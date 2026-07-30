extends Node3D

## Builds the city from Config.LOCATIONS. Everything random here is drawn from
## _rng, which is seeded from the host's seed — so every machine in the session
## generates a byte-identical city without any of it going over the wire.
##
## Array.shuffle() deliberately is not used: it draws from the global RNG,
## which is not seeded, and would put different locations on different blocks
## for every player.
##
## Structure: a grid of rectangular blocks, each column and row drawing its own
## size. Every block is sliced along its width into lots; a lot may be vacant,
## and a building may span two adjacent lots. At most one named location per
## block, so landmarks stay spread out instead of clustering.

var is_built := false

var _rng := RandomNumberGenerator.new()
var _spawn_points: Array[Vector3] = []

# Per-column and per-row block geometry, in centered world coordinates.
var _col_x: Array[float] = []   # min X edge of each column
var _col_w: Array[float] = []
var _row_z: Array[float] = []   # min Z edge of each row
var _row_d: Array[float] = []

func build(city_seed: int) -> void:
	# Detach before freeing: queue_free() is deferred, so the old city would
	# still be in the tree while the new one is being added.
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_rng.seed = city_seed
	_build_grid()
	_build_ground()
	_build_blocks()
	_build_spawn_points()
	is_built = true

# --- Grid -------------------------------------------------------------------
## Lay out column widths and row depths, then center the whole thing on origin.
func _build_grid() -> void:
	_col_x.clear()
	_col_w.clear()
	_row_z.clear()
	_row_d.clear()

	var x := 0.0
	for i in Config.GRID_SIZE:
		var w := _rng.randf_range(Config.BLOCK_MIN_WIDTH, Config.BLOCK_MAX_WIDTH)
		_col_x.append(x)
		_col_w.append(w)
		x += w + Config.STREET_WIDTH
	var total_x := x - Config.STREET_WIDTH

	var z := 0.0
	for i in Config.GRID_SIZE:
		var d := _rng.randf_range(Config.BLOCK_MIN_DEPTH, Config.BLOCK_MAX_DEPTH)
		_row_z.append(z)
		_row_d.append(d)
		z += d + Config.STREET_WIDTH
	var total_z := z - Config.STREET_WIDTH

	for i in Config.GRID_SIZE:
		_col_x[i] -= total_x * 0.5
		_row_z[i] -= total_z * 0.5

## Full span of the built city, centered on origin. Public because the preview
## harness frames its cameras from it.
func extent() -> float:
	var x := _col_x[Config.GRID_SIZE - 1] + _col_w[Config.GRID_SIZE - 1]
	var z := _row_z[Config.GRID_SIZE - 1] + _row_d[Config.GRID_SIZE - 1]
	return maxf(x, z) * 2.0

# --- Blocks and lots --------------------------------------------------------
func _build_blocks() -> void:
	var total := Config.GRID_SIZE * Config.GRID_SIZE

	var landmarks: Array[Dictionary] = []
	for row in Config.LOCATIONS:
		landmarks.append(row)
	_shuffle(landmarks)

	# Scatter the named locations across distinct blocks.
	var order: Array[int] = []
	for i in total:
		order.append(i)
	_shuffle(order)
	var landmark_of := {}
	for i in mini(landmarks.size(), total):
		landmark_of[order[i]] = landmarks[i]

	var index := 0
	for cx in Config.GRID_SIZE:
		for cz in Config.GRID_SIZE:
			_build_block(cx, cz, landmark_of.get(index, {}))
			index += 1

func _build_block(cx: int, cz: int, landmark: Dictionary) -> void:
	var block_x := _col_x[cx]
	var block_z := _row_z[cz]
	var width := _col_w[cx]
	var depth := _row_d[cz]

	var slots := _slice_into_lots(width)
	if slots.is_empty():
		return

	# The landmark takes the widest lot and is never left vacant. A named
	# location that lost a coin flip or came out a sliver would vanish from the
	# city entirely, and the game is about finding these places.
	var landmark_slot := -1
	if not landmark.is_empty():
		landmark_slot = 0
		for i in slots.size():
			if slots[i].y > slots[landmark_slot].y:
				landmark_slot = i

	for i in slots.size():
		var is_landmark := i == landmark_slot
		var row: Dictionary = landmark if is_landmark \
			else {"name": _filler_name(), "kind": "block"}
		var vacant := _rng.randf() < Config.LOT_EMPTY_CHANCE
		if vacant and not is_landmark:
			continue
		_build_on_lot(row, block_x + slots[i].x, slots[i].y, block_z, depth, is_landmark)

## Slice the block width into lots of varying width, merging some adjacent
## pairs so a building can span two. Returns Vector2(offset, width) per slot.
func _slice_into_lots(width: float) -> Array[Vector2]:
	var count := _rng.randi_range(Config.LOTS_MIN, Config.LOTS_MAX)

	var weights: Array[float] = []
	var total_weight := 0.0
	for i in count:
		var w := _rng.randf_range(Config.LOT_WEIGHT_MIN, Config.LOT_WEIGHT_MAX)
		weights.append(w)
		total_weight += w

	# Cumulative lot boundaries across the block.
	var edges: Array[float] = [0.0]
	var running := 0.0
	for i in count:
		running += width * weights[i] / total_weight
		edges.append(running)

	var slots: Array[Vector2] = []
	var i := 0
	while i < count:
		var span := 1
		if i + 1 < count and _rng.randf() < Config.LOT_MERGE_CHANCE:
			span = 2
		slots.append(Vector2(edges[i], edges[i + span] - edges[i]))
		i += span
	return slots

## Place one building inside a lot: inset from the lot lines on each side, set
## back independently from the two street frontages.
func _build_on_lot(row: Dictionary, lot_x: float, lot_width: float,
		block_z: float, block_depth: float, required: bool = false) -> void:
	var gap_left := _rng.randf_range(Config.LOT_SIDE_GAP_MIN, Config.LOT_SIDE_GAP_MAX)
	var gap_right := _rng.randf_range(Config.LOT_SIDE_GAP_MIN, Config.LOT_SIDE_GAP_MAX)
	var build_width := lot_width - gap_left - gap_right

	var front := _rng.randf_range(Config.SETBACK_FRONT_MIN, Config.SETBACK_FRONT_MAX)
	var rear := _rng.randf_range(Config.SETBACK_REAR_MIN, Config.SETBACK_REAR_MAX)
	var build_depth := block_depth - front - rear

	# A sliver reads as a glitch; leave the lot vacant instead. A required
	# building (a named location) instead gives up its gaps to fit.
	if build_width < Config.LOT_MIN_BUILD_WIDTH:
		if not required:
			return
		build_width = minf(Config.LOT_MIN_BUILD_WIDTH, lot_width)
		gap_left = (lot_width - build_width) * 0.5
	if build_depth < Config.LOT_MIN_BUILD_DEPTH:
		if not required:
			return
		build_depth = minf(Config.LOT_MIN_BUILD_DEPTH, block_depth)
		front = (block_depth - build_depth) * 0.5

	var height := _rng.randf_range(Config.BUILDING_MIN_HEIGHT, Config.BUILDING_MAX_HEIGHT)
	var center := Vector3(
		lot_x + gap_left + build_width * 0.5,
		0.0,
		block_z + front + build_depth * 0.5
	)
	_build_building(row, center, Vector3(build_width, height, build_depth))

# --- Spawns -----------------------------------------------------------------
## Distinct street intersections, ordered deterministically so every machine
## agrees on which player starts where.
func spawn_point(index: int) -> Vector3:
	if _spawn_points.is_empty():
		return Vector3(0.0, Config.PLAYER_HEIGHT, 0.0)
	if Config.SPAWN_TOGETHER:
		# Ringed around one intersection: visible immediately, not overlapping.
		var angle := TAU * float(index) / float(Config.MAX_PLAYERS)
		return _spawn_points[0] + Vector3(cos(angle), 0.0, sin(angle)) * Config.SPAWN_SPREAD
	return _spawn_points[index % _spawn_points.size()]

## Street corners, in the same deterministic order on every machine. The debug
## teleport picks from these; nothing else should need them.
func corner_count() -> int:
	return _spawn_points.size()

func corner(index: int) -> Vector3:
	if _spawn_points.is_empty():
		return Vector3(0.0, Config.PLAYER_HEIGHT, 0.0)
	return _spawn_points[index % _spawn_points.size()]

## Every named location in the built city: name, kind, and where it stands.
## Reads the metas rather than Config.LOCATIONS, because the question callers
## ask is "what is out there and where", which only the built tree knows.
## Filler blocks are excluded — they are scenery, not places.
func landmarks() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for child in get_children():
		if not child.has_meta(&"location_kind"):
			continue
		if child.get_meta(&"location_kind") == "block":
			continue
		out.append({
			"name": child.get_meta(&"location_name"),
			"kind": child.get_meta(&"location_kind"),
			"position": child.position,
			"height": child.get_meta(&"building_height"),
		})
	return out

func _build_spawn_points() -> void:
	var candidates: Array[Vector3] = []
	var half_street := Config.STREET_WIDTH * 0.5
	# Intersections sit between blocks, so index 1..GRID_SIZE-1.
	for x in range(1, Config.GRID_SIZE):
		for z in range(1, Config.GRID_SIZE):
			candidates.append(Vector3(
				_col_x[x] - half_street, Config.PLAYER_HEIGHT, _row_z[z] - half_street
			))
	_shuffle(candidates)
	_spawn_points = candidates

# --- Geometry ---------------------------------------------------------------
func _build_ground() -> void:
	var size := extent() + Config.GROUND_MARGIN

	var body := StaticBody3D.new()
	body.name = "Ground"
	add_child(body)

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(size, 1.0, size)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.14, 0.14, 0.16)
	mesh.material_override = mat
	mesh.position.y = -0.5
	body.add_child(mesh)

	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(size, 1.0, size)
	shape.shape = box_shape
	shape.position.y = -0.5
	body.add_child(shape)

func _build_building(row: Dictionary, center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = str(row["name"]).validate_node_name()
	body.position = center
	# Node names are sanitized and deduplicated, so they are not the label and
	# cannot be compared against Config.LOCATIONS. The tools read these instead.
	body.set_meta(&"location_name", row["name"])
	body.set_meta(&"location_kind", row["kind"])
	body.set_meta(&"footprint", Rect2(
		center.x - size.x * 0.5, center.z - size.z * 0.5, size.x, size.z
	))
	body.set_meta(&"building_height", size.y)
	add_child(body)

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	var base: Color = Config.KIND_COLORS[row["kind"]]
	mat.albedo_color = base.lerp(Color.BLACK, _rng.randf_range(0.0, 0.2))
	mesh.material_override = mat
	mesh.position.y = size.y * 0.5
	body.add_child(mesh)

	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	shape.position.y = size.y * 0.5
	body.add_child(shape)

	body.add_child(_build_sign(row, size.y))

func _build_sign(row: Dictionary, height: float) -> Label3D:
	var is_landmark: bool = row["kind"] != "block"
	var range_end: float = Config.LABEL_LANDMARK_RANGE if is_landmark else Config.LABEL_FILLER_RANGE

	var label := Label3D.new()
	label.text = row["name"]
	label.font_size = Config.LABEL_FONT_SIZE
	label.pixel_size = Config.LABEL_PIXEL_SIZE
	if is_landmark:
		label.pixel_size *= Config.LABEL_LANDMARK_SCALE
	label.outline_size = Config.LABEL_OUTLINE_SIZE
	label.modulate = Color.WHITE if is_landmark else Color(0.75, 0.75, 0.78)
	label.outline_modulate = Color(0.0, 0.0, 0.0, 0.85)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.double_sided = true
	label.no_depth_test = false
	label.fixed_size = false
	label.visibility_range_end = range_end
	label.visibility_range_end_margin = range_end * 0.2
	label.position.y = height + Config.LABEL_HEIGHT_ABOVE_ROOF
	return label

# --- Helpers ----------------------------------------------------------------
## Seeded Fisher-Yates. See the note at the top about Array.shuffle().
func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp

func _filler_name() -> String:
	var prefix: String = Config.FILLER_PREFIX[_rng.randi() % Config.FILLER_PREFIX.size()]
	var suffix: String = Config.FILLER_SUFFIX[_rng.randi() % Config.FILLER_SUFFIX.size()]
	return "%s %s" % [prefix, suffix]
