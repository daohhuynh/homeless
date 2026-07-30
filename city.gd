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

func build(city_seed: int) -> void  # deliberate CI red test
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

	# Two rows of buildings back to back, split unevenly. The first faces the
	# street on the -Z side, the second the street on +Z, and neither may reach
	# past the line they share — so the two rows cannot overlap by construction
	# rather than by a check.
	var split := _rng.randf_range(Config.ROW_SPLIT_MIN, Config.ROW_SPLIT_MAX)
	var bands: Array[Vector2] = [
		Vector2(block_z, depth * split),
		Vector2(block_z + depth * split, depth * (1.0 - split)),
	]

	# Sliced per row, so the two rows do not share lot lines. A block reads as
	# two streets' worth of frontage rather than as one building sawn in half.
	var slots: Array[Array] = []
	for b in bands.size():
		slots.append(_slice_into_lots(width))

	# The landmark takes the widest lot in the block, either row, and is never
	# left vacant. A named location that lost a coin flip or came out a sliver
	# would vanish from the city entirely, and the game is about finding these
	# places.
	var landmark_band := -1
	var landmark_slot := -1
	if not landmark.is_empty():
		var widest := -1.0
		for b in bands.size():
			var band_slots: Array[Vector2] = slots[b]
			for i in band_slots.size():
				if band_slots[i].y > widest:
					widest = band_slots[i].y
					landmark_band = b
					landmark_slot = i

	for b in bands.size():
		var band_slots: Array[Vector2] = slots[b]
		for i in band_slots.size():
			var is_landmark: bool = b == landmark_band and i == landmark_slot
			var row: Dictionary = landmark if is_landmark \
				else {"name": _filler_name(), "kind": "block"}
			var vacant := _rng.randf() < Config.LOT_EMPTY_CHANCE
			if vacant and not is_landmark:
				continue
			_build_on_lot(row, block_x + band_slots[i].x, band_slots[i].y,
				bands[b], b == 0, is_landmark)

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
## back from its own street, and held off the line its row shares with the other.
## The band is Vector2(min Z, depth) of the row this lot belongs to.
func _build_on_lot(row: Dictionary, lot_x: float, lot_width: float,
		band: Vector2, faces_negative_z: bool, required: bool = false) -> void:
	var band_z := band.x
	var band_depth := band.y

	var gap_left := _rng.randf_range(Config.LOT_SIDE_GAP_MIN, Config.LOT_SIDE_GAP_MAX)
	var gap_right := _rng.randf_range(Config.LOT_SIDE_GAP_MIN, Config.LOT_SIDE_GAP_MAX)
	var build_width := lot_width - gap_left - gap_right

	var front := _rng.randf_range(Config.SETBACK_FRONT_MIN, Config.SETBACK_FRONT_MAX)
	var rear := _rng.randf_range(Config.SETBACK_REAR_MIN, Config.SETBACK_REAR_MAX)
	var build_depth := band_depth - front - rear

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
		# A required building gives up its setbacks rather than its footprint, the
		# way it gives up its side gaps above. A named location four metres deep
		# across a thirty metre frontage reads as a wall, not a building — and it
		# is the shape the models cannot absorb, since depth is where they are
		# already being stretched.
		build_depth = band_depth
		front = 0.0
		rear = 0.0

	# Which setback sits at the low-Z edge of the band depends on which way the
	# row faces: the front setback is always the one against the street.
	var lead := front if faces_negative_z else rear

	var height := _rng.randf_range(Config.BUILDING_MIN_HEIGHT, Config.BUILDING_MAX_HEIGHT)
	var center := Vector3(
		lot_x + gap_left + build_width * 0.5,
		0.0,
		band_z + lead + build_depth * 0.5
	)
	_build_building(row, center, Vector3(build_width, height, build_depth), faces_negative_z)

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

func _build_building(row: Dictionary, center: Vector3, size: Vector3,
		faces_negative_z: bool) -> void:
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
	add_child(body)

	# A modelled kind keeps the lot's footprint but gets its own height, because
	# a model stretched to an arbitrary height stops reading as a building.
	var height := size.y
	if Config.BUILDING_MODELS.has(row["kind"]):
		height = _add_model(body, row, size, faces_negative_z)
	else:
		_add_box(body, row, size)
	body.set_meta(&"building_height", height)

	# Collision stays a box on the lot footprint whatever the mesh is. The kit's
	# stoops and overhangs are centimetres at this scale, and the walkability
	# invariant is written against the footprint.
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(size.x, height, size.z)
	shape.shape = box_shape
	shape.position.y = height * 0.5
	body.add_child(shape)

	body.add_child(_build_sign(row, height))

func _add_box(body: StaticBody3D, row: Dictionary, size: Vector3) -> void:
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

# --- Models -----------------------------------------------------------------
## Fit a kit model to the lot and return the height it came out at.
##
## The kit's own colours come off its texture atlas, so KIND_COLORS does not
## apply here: a modelled kind is no longer colour-coded, and its sign is the
## only thing left saying what it is.
func _add_model(body: StaticBody3D, row: Dictionary, size: Vector3,
		faces_negative_z: bool) -> float:
	var info := _pick_model(Config.BUILDING_MODELS[row["kind"]], size)
	var box: AABB = info["aabb"]

	var scale_x := size.x / box.size.x
	var scale_z := size.z / box.size.z
	# Vertical scale is the mean of the two horizontal ones rather than a draw
	# from the height range: that keeps storey heights and window proportions
	# honest against the width. Clamped, so a tower-shaped model on a broad lot
	# still lands inside the range the rest of the city is drawn from.
	var height := clampf(box.size.y * (scale_x + scale_z) * 0.5,
		Config.BUILDING_MIN_HEIGHT, Config.BUILDING_MAX_HEIGHT)

	var node: Node3D = (info["scene"] as PackedScene).instantiate()
	var yaw := deg_to_rad(Config.MODEL_YAW_DEGREES)
	if not faces_negative_z:
		yaw += PI
	var basis := Basis.from_euler(Vector3(0.0, yaw, 0.0)) \
		* Basis.IDENTITY.scaled(Vector3(scale_x, height / box.size.y, scale_z))
	# Anchor the model's own base centre to the lot centre at ground level. The
	# kit already models its origin there, but measuring rather than assuming is
	# what makes the next kit a config row instead of a debugging session.
	var anchor := Vector3(box.get_center().x, box.position.y, box.get_center().z)
	node.transform = Transform3D(basis, -(basis * anchor))
	body.add_child(node)
	return height

## Nearest footprint ratio wins, with the nearest few entered into a draw. The
## comparison is in log space so a lot twice as wide as the model scores the
## same as one half as wide.
func _pick_model(paths: Array, size: Vector3) -> Dictionary:
	var wanted := log(size.x / size.z)
	var ranked: Array[Dictionary] = []
	for path in paths:
		var box: AABB = _model(path)["aabb"]
		ranked.append({
			"path": path,
			"error": absf(log(box.size.x / box.size.z) - wanted),
		})
	# Path breaks ties: sort_custom is not stable, and two models with the same
	# ratio must not resolve differently on two machines.
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if is_equal_approx(a["error"], b["error"]):
			return a["path"] < b["path"]
		return a["error"] < b["error"])
	var span := mini(Config.MODEL_ASPECT_CANDIDATES, ranked.size())
	return _model(ranked[_rng.randi_range(0, span - 1)]["path"])

## Scene plus measured bounds, keyed by path. Static because a reshuffle would
## otherwise instantiate every model again just to measure it again.
static var _model_cache := {}

func _model(path: String) -> Dictionary:
	if _model_cache.has(path):
		return _model_cache[path]
	var scene: PackedScene = load(path)
	var probe: Node3D = scene.instantiate()
	var info := {"scene": scene, "aabb": _mesh_bounds(probe)}
	probe.free()
	_model_cache[path] = info
	return info

## Bounds of the visible mesh, not of the scene: an imported kit model can carry
## empty nodes, and a node's own transform is part of where its mesh ends up.
func _mesh_bounds(node: Node, xform := Transform3D.IDENTITY) -> AABB:
	var boxes: Array[AABB] = []
	_collect_bounds(node, xform, boxes)
	if boxes.is_empty():
		return AABB()
	var merged := boxes[0]
	for i in range(1, boxes.size()):
		merged = merged.merge(boxes[i])
	return merged

func _collect_bounds(node: Node, xform: Transform3D, out: Array[AABB]) -> void:
	var here := xform
	if node is Node3D:
		here = xform * (node as Node3D).transform
	if node is MeshInstance3D:
		out.append(here * (node as MeshInstance3D).get_aabb())
	for child in node.get_children():
		_collect_bounds(child, here, out)

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
