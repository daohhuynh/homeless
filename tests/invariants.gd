extends SceneTree

## City generation invariants. Run:
##
##   godot --headless --path . --script tests/invariants.gd
##
## Exits non-zero if any invariant fails, so it can gate a commit.
##
## These are the four properties the rest of the design leans on. Determinism
## is what lets the city stay off the wire. Non-overlap is what makes the city
## look built rather than glitched. Presence and reachability are what make
## "go find the Day Labor Center" a task rather than a coin flip — a named
## location that did not spawn, or spawned walled in, turns a run into a
## wild goose chase that the players cannot tell apart from being lost.

const CityScript := preload("res://city.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	print("City invariants — %d seeds, cell %.2fm\n" % [
		Config.TEST_SEEDS.size(), Config.TEST_CELL_SIZE
	])

	for city_seed in Config.TEST_SEEDS:
		_check_seed(city_seed)

	print("")
	if _failures.is_empty():
		print("PASS — %d seeds, 4 invariants each." % Config.TEST_SEEDS.size())
		quit(0)
		return
	print("FAIL — %d failure(s):" % _failures.size())
	for failure in _failures:
		print("  " + failure)
	quit(1)

func _check_seed(city_seed: int) -> void:
	var city := _build(city_seed)
	var twin := _build(city_seed)

	var started := Time.get_ticks_msec()
	_check_determinism(city_seed, city, twin)
	twin.free()

	var buildings := _buildings(city)
	_check_no_overlaps(city_seed, buildings)
	_check_locations_present(city_seed, buildings)
	_check_locations_reachable(city_seed, city, buildings)

	print("  seed %-10d %3d buildings, %4dms" % [
		city_seed, buildings.size(), Time.get_ticks_msec() - started
	])
	city.free()

func _build(city_seed: int) -> Node3D:
	var city: Node3D = CityScript.new()
	root.add_child(city)
	city.build(city_seed)
	return city

## Every building, as a dictionary of its metadata plus its world transform.
func _buildings(city: Node3D) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for child in city.get_children():
		if not child.has_meta(&"location_name"):
			continue
		out.append({
			"name": child.get_meta(&"location_name"),
			"kind": child.get_meta(&"location_kind"),
			"footprint": child.get_meta(&"footprint"),
			"height": child.get_meta(&"building_height"),
			"position": child.position,
		})
	return out

# --- 1. Determinism ---------------------------------------------------------
## Two independent builds of one seed must agree bit for bit. Not "look the
## same": the whole networking model is that the seed is the map, so a float
## that differs in its last bit on one machine is a player walking into a wall
## nobody else can see.
func _check_determinism(city_seed: int, city: Node3D, twin: Node3D) -> void:
	var a := _fingerprint(city)
	var b := _fingerprint(twin)
	if a == b:
		return
	var detail := "%d bytes vs %d bytes" % [a.size(), b.size()]
	if a.size() == b.size():
		for i in a.size():
			if a[i] != b[i]:
				detail = "first difference at byte %d of %d" % [i, a.size()]
				break
	_fail(city_seed, "determinism", "two builds of the same seed differ (%s)" % detail)

## Ordered dump of everything the city places. Node order is build order, which
## is itself part of what has to be deterministic, so it is not sorted.
func _fingerprint(city: Node3D) -> PackedByteArray:
	var dump: Array = []
	for child in city.get_children():
		if child.has_meta(&"location_name"):
			dump.append([
				child.get_meta(&"location_name"),
				child.get_meta(&"location_kind"),
				child.position,
				child.get_meta(&"footprint"),
				child.get_meta(&"building_height"),
			])
		else:
			dump.append([child.name, child.position])
	dump.append(city.extent())
	for i in city.corner_count():
		dump.append(city.corner(i))
	return var_to_bytes(dump)

# --- 2. No overlapping buildings --------------------------------------------
## Full pairwise, not a broadphase. There are ~150 buildings; the honest
## quadratic answer costs milliseconds and cannot have a bug in its acceleration
## structure.
func _check_no_overlaps(city_seed: int, buildings: Array[Dictionary]) -> void:
	var overlaps := 0
	var worst := ""
	for i in buildings.size():
		var a: Rect2 = buildings[i]["footprint"]
		for j in range(i + 1, buildings.size()):
			var b: Rect2 = buildings[j]["footprint"]
			# Shared lot lines are legal, shared volume is not, so measure the
			# intersection rather than testing for one.
			var overlap_x := minf(a.end.x, b.end.x) - maxf(a.position.x, b.position.x)
			var overlap_y := minf(a.end.y, b.end.y) - maxf(a.position.y, b.position.y)
			if overlap_x <= Config.TEST_OVERLAP_EPSILON \
					or overlap_y <= Config.TEST_OVERLAP_EPSILON:
				continue
			overlaps += 1
			if worst.is_empty():
				worst = "%s x %s by %.3fm x %.3fm" % [
					buildings[i]["name"], buildings[j]["name"], overlap_x, overlap_y
				]
	if overlaps > 0:
		_fail(city_seed, "no overlaps", "%d overlapping pair(s), first: %s" % [overlaps, worst])

# --- 3. Every named location present ----------------------------------------
func _check_locations_present(city_seed: int, buildings: Array[Dictionary]) -> void:
	var placed := {}
	for building in buildings:
		if building["kind"] != "block":
			placed[building["name"]] = placed.get(building["name"], 0) + 1

	var missing: Array[String] = []
	var duplicated: Array[String] = []
	for row in Config.LOCATIONS:
		var count: int = placed.get(row["name"], 0)
		if count == 0:
			missing.append(row["name"])
		elif count > 1:
			duplicated.append("%s x%d" % [row["name"], count])

	if not missing.is_empty():
		_fail(city_seed, "locations present", "missing: %s" % ", ".join(missing))
	if not duplicated.is_empty():
		_fail(city_seed, "locations present", "duplicated: %s" % ", ".join(duplicated))

# --- 4. Every named location reachable on foot ------------------------------
## Rasterize the walkable ground, flood fill from a street corner, then check
## that every named location has walkable ground at its door. Cells are the
## player's own width, so a gap the player cannot squeeze through does not
## count as a route.
func _check_locations_reachable(city_seed: int, city: Node3D,
		buildings: Array[Dictionary]) -> void:
	var cell := Config.TEST_CELL_SIZE
	var half: float = city.extent() * 0.5 + Config.GROUND_MARGIN * 0.5
	var side := int(ceil(half * 2.0 / cell))
	var origin := Vector2(-half, -half)

	# A building blocks every cell its footprint reaches, grown by the player's
	# radius: the capsule cannot stand where its edge would be inside a wall.
	var blocked := PackedByteArray()
	blocked.resize(side * side)
	for building in buildings:
		var rect: Rect2 = building["footprint"]
		rect = rect.grow(Config.PLAYER_RADIUS)
		var x0 := maxi(0, int(floor((rect.position.x - origin.x) / cell)))
		var x1 := mini(side - 1, int(ceil((rect.end.x - origin.x) / cell)))
		var y0 := maxi(0, int(floor((rect.position.y - origin.y) / cell)))
		var y1 := mini(side - 1, int(ceil((rect.end.y - origin.y) / cell)))
		for y in range(y0, y1 + 1):
			var row_base := y * side
			for x in range(x0, x1 + 1):
				var center := origin + Vector2(x + 0.5, y + 0.5) * cell
				if rect.has_point(center):
					blocked[row_base + x] = 1

	var start: Vector3 = city.corner(0)
	var start_x := int((start.x - origin.x) / cell)
	var start_y := int((start.z - origin.y) / cell)
	if start_x < 0 or start_x >= side or start_y < 0 or start_y >= side \
			or blocked[start_y * side + start_x] == 1:
		_fail(city_seed, "reachability", "spawn corner is not on walkable ground")
		return

	var reached := _flood(blocked, side, start_y * side + start_x)

	var unreachable: Array[String] = []
	for building in buildings:
		if building["kind"] == "block":
			continue
		if not _has_reached_cell_near(reached, blocked, side, origin, cell,
				building["footprint"]):
			unreachable.append(building["name"])
	if not unreachable.is_empty():
		_fail(city_seed, "reachability", "walled in: %s" % ", ".join(unreachable))

func _flood(blocked: PackedByteArray, side: int, start: int) -> PackedByteArray:
	var reached := PackedByteArray()
	reached.resize(side * side)
	reached[start] = 1

	var queue := PackedInt32Array([start])
	var head := 0
	while head < queue.size():
		var index := queue[head]
		head += 1
		var x := index % side
		var y := index / side
		if x > 0:
			_visit(blocked, reached, queue, index - 1)
		if x < side - 1:
			_visit(blocked, reached, queue, index + 1)
		if y > 0:
			_visit(blocked, reached, queue, index - side)
		if y < side - 1:
			_visit(blocked, reached, queue, index + side)
	return reached

func _visit(blocked: PackedByteArray, reached: PackedByteArray,
		queue: PackedInt32Array, index: int) -> void:
	if reached[index] == 1 or blocked[index] == 1:
		return
	reached[index] = 1
	queue.append(index)

## Standing at the door: a walkable, flood-reached cell within the reach margin
## of the footprint. Nothing here requires a door to exist yet — interiors are
## phase C — only that a player can walk up and touch the building.
func _has_reached_cell_near(reached: PackedByteArray, blocked: PackedByteArray,
		side: int, origin: Vector2, cell: float, footprint: Rect2) -> bool:
	var rect := footprint.grow(Config.PLAYER_RADIUS + Config.TEST_REACH_MARGIN)
	var x0 := maxi(0, int(floor((rect.position.x - origin.x) / cell)))
	var x1 := mini(side - 1, int(ceil((rect.end.x - origin.x) / cell)))
	var y0 := maxi(0, int(floor((rect.position.y - origin.y) / cell)))
	var y1 := mini(side - 1, int(ceil((rect.end.y - origin.y) / cell)))
	for y in range(y0, y1 + 1):
		var row_base := y * side
		for x in range(x0, x1 + 1):
			var index := row_base + x
			if blocked[index] == 1 or reached[index] == 0:
				continue
			if rect.has_point(origin + Vector2(x + 0.5, y + 0.5) * cell):
				return true
	return false

# --- Reporting --------------------------------------------------------------
func _fail(city_seed: int, invariant: String, detail: String) -> void:
	_failures.append("seed %d — %s: %s" % [city_seed, invariant, detail])
