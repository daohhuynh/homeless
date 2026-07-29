extends Node3D

## Builds the city from Config.LOCATIONS. Everything random here is drawn from
## _rng, which is seeded from the host's seed — so every machine in the session
## generates a byte-identical city without any of it going over the wire.
##
## Array.shuffle() deliberately is not used: it draws from the global RNG,
## which is not seeded, and would put different locations on different blocks
## for every player.

var is_built := false

var _rng := RandomNumberGenerator.new()
var _spawn_points: Array[Vector3] = []

## Block pitch: one buildable cell plus the street on one side of it.
func _pitch() -> float:
	return Config.CELL_SIZE + Config.STREET_WIDTH

func _span() -> float:
	return _pitch() * Config.GRID_SIZE

## Center of block (x, z) in world space.
func _cell_center(x: int, z: int) -> Vector3:
	var origin := -_span() * 0.5 + Config.STREET_WIDTH * 0.5 + Config.CELL_SIZE * 0.5
	return Vector3(origin + x * _pitch(), 0.0, origin + z * _pitch())

func build(city_seed: int) -> void:
	# Detach before freeing: queue_free() is deferred, so the old city would
	# still be in the tree while the new one is being added.
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_rng.seed = city_seed
	_build_ground()
	_build_blocks()
	_build_spawn_points()
	is_built = true

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

func _build_spawn_points() -> void:
	var candidates: Array[Vector3] = []
	var offset := _pitch() * 0.5
	# Intersections sit between cells, so index 1..GRID_SIZE-1.
	for x in range(1, Config.GRID_SIZE):
		for z in range(1, Config.GRID_SIZE):
			var corner := _cell_center(x, z)
			candidates.append(Vector3(
				corner.x - offset, Config.PLAYER_HEIGHT, corner.z - offset
			))
	_shuffle(candidates)
	_spawn_points = candidates

func _build_ground() -> void:
	var size := _span() + Config.GROUND_MARGIN

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

func _build_blocks() -> void:
	var rows := _shuffled_rows(Config.GRID_SIZE * Config.GRID_SIZE)
	var i := 0
	for x in Config.GRID_SIZE:
		for z in Config.GRID_SIZE:
			var row: Dictionary = rows[i]
			i += 1
			if row.is_empty():
				continue  # empty lot
			_build_building(row, _cell_center(x, z))

## One row per grid cell: every named location appears exactly once, the rest
## are plausible filler, and some cells are empty lots (an empty Dictionary).
func _shuffled_rows(count: int) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for row in Config.LOCATIONS:
		rows.append(row)
	_shuffle(rows)
	if rows.size() > count:
		rows.resize(count)

	while rows.size() < count:
		if _rng.randf() < Config.EMPTY_LOT_CHANCE:
			rows.append({})
		else:
			rows.append({"name": _filler_name(), "kind": "block"})

	# Named locations were front-loaded above; shuffle again so they scatter.
	_shuffle(rows)
	return rows

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

func _build_building(row: Dictionary, center: Vector3) -> void:
	var footprint := Vector2(
		Config.CELL_SIZE - _rng.randf_range(Config.BUILDING_MIN_INSET, Config.BUILDING_MAX_INSET),
		Config.CELL_SIZE - _rng.randf_range(Config.BUILDING_MIN_INSET, Config.BUILDING_MAX_INSET)
	)
	var height := _rng.randf_range(Config.BUILDING_MIN_HEIGHT, Config.BUILDING_MAX_HEIGHT)
	var size := Vector3(footprint.x, height, footprint.y)

	var body := StaticBody3D.new()
	body.name = str(row["name"]).validate_node_name()
	body.position = center
	add_child(body)

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	var base: Color = Config.KIND_COLORS[row["kind"]]
	mat.albedo_color = base.lerp(Color.BLACK, _rng.randf_range(0.0, 0.2))
	mesh.material_override = mat
	mesh.position.y = height * 0.5
	body.add_child(mesh)

	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	shape.position.y = height * 0.5
	body.add_child(shape)

	body.add_child(_build_sign(row, height))

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
