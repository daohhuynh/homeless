extends Node3D

## Builds the city from Config.LOCATIONS every run. The grid layout is fixed;
## which location lands on which block is shuffled per run, so nobody can
## memorize the map across sessions.

@export var player_path: NodePath = ^"../Player"

var _rng := RandomNumberGenerator.new()

## Block pitch: one buildable cell plus the street on one side of it.
func _pitch() -> float:
	return Config.CELL_SIZE + Config.STREET_WIDTH

func _span() -> float:
	return _pitch() * Config.GRID_SIZE

## Center of block (x, z) in world space.
func _cell_center(x: int, z: int) -> Vector3:
	var origin := -_span() * 0.5 + Config.STREET_WIDTH * 0.5 + Config.CELL_SIZE * 0.5
	return Vector3(origin + x * _pitch(), 0.0, origin + z * _pitch())

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == Config.KEY_RESHUFFLE:
		get_viewport().set_input_as_handled()
		# Deferred: reloading mid-input would free this node while it is
		# still dispatching.
		get_tree().call_deferred(&"reload_current_scene")

func _ready() -> void:
	_rng.randomize()
	_build_ground()
	_build_blocks()
	_place_player()

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
	rows.shuffle()
	if rows.size() > count:
		rows.resize(count)

	while rows.size() < count:
		if _rng.randf() < Config.EMPTY_LOT_CHANCE:
			rows.append({})
		else:
			rows.append({"name": _filler_name(), "kind": "block"})

	# Named locations were front-loaded above; shuffle again so they scatter.
	rows.shuffle()
	return rows

func _filler_name() -> String:
	var prefix: String = Config.FILLER_PREFIX[_rng.randi() % Config.FILLER_PREFIX.size()]
	var suffix: String = Config.FILLER_SUFFIX[_rng.randi() % Config.FILLER_SUFFIX.size()]
	return "%s %s" % [prefix, suffix]

func _build_building(row: Dictionary, center: Vector3) -> void:
	var inset := _rng.randf_range(Config.BUILDING_MIN_INSET, Config.BUILDING_MAX_INSET)
	var footprint := Vector2(
		Config.CELL_SIZE - inset,
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

## Drop the player on a random street intersection facing a random direction.
## Same-spawn-every-run is the strongest "I've been here before" signal there
## is, and it made a genuinely reshuffled city read as identical.
func _place_player() -> void:
	var player := get_node_or_null(player_path)
	if not player is Node3D:
		return
	# Intersections sit between cells, so index 1..GRID_SIZE-1.
	var gx := _rng.randi_range(1, Config.GRID_SIZE - 1)
	var gz := _rng.randi_range(1, Config.GRID_SIZE - 1)
	var corner := _cell_center(gx, gz)
	var offset := _pitch() * 0.5
	player.global_position = Vector3(
		corner.x - offset, Config.PLAYER_HEIGHT, corner.z - offset
	)
	player.rotation.y = _rng.randf_range(-PI, PI)
