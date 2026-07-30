extends Node

## Three debug tools, all bound in Config, all local-only:
##
##   T   teleport to a random street corner
##   F   toggle a free-fly camera that leaves your body behind
##   F3  toggle the seed readout
##
## Nothing here is a game mechanic and nothing here is authoritative. The one
## exception is the teleport, which has to tell the host where it went — the
## host simulates every body, so a client that moved only itself would be
## reconciled straight back to where it was standing.

@onready var city: Node3D = get_parent().get_node(^"City")
@onready var players_root: Node3D = get_parent().get_node(^"Players")

var _flying := false
var _fly_camera: Camera3D
var _fly_velocity := Vector3.ZERO
var _fly_yaw := 0.0
var _fly_pitch := 0.0

var _hud: CanvasLayer
var _readout: Label

func _ready() -> void:
	_build_hud()
	_build_fly_camera()

# --- Keys -------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if _flying and event is InputEventMouseMotion \
			and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_fly_yaw = wrapf(_fly_yaw - event.relative.x * Config.MOUSE_SENSITIVITY, -PI, PI)
		_fly_pitch = clampf(
			_fly_pitch - event.relative.y * Config.MOUSE_SENSITIVITY,
			-Config.PITCH_LIMIT, Config.PITCH_LIMIT
		)
		get_viewport().set_input_as_handled()
		return

	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		Config.KEY_TELEPORT:
			get_viewport().set_input_as_handled()
			_teleport_to_random_corner()
		Config.KEY_FREEFLY:
			get_viewport().set_input_as_handled()
			_set_flying(not _flying)
		Config.KEY_DEBUG_HUD:
			get_viewport().set_input_as_handled()
			_hud.visible = not _hud.visible
			# Also to stdout: the seed is what you paste into the preview
			# harness, and you cannot copy it off the screen.
			print("city seed: %d" % Net.city_seed)

# --- Teleport ---------------------------------------------------------------
## Deliberately uses the global RNG rather than the city's: the city's RNG is
## the map, and a debug key must never be able to shift it.
func _teleport_to_random_corner() -> void:
	if not city.is_built or city.corner_count() == 0:
		return
	var target: Vector3 = city.corner(randi() % city.corner_count())
	target.y += Config.DEBUG_TELEPORT_CLEARANCE

	if _flying:
		_fly_camera.global_position = target
		return

	var player := _local_player()
	if player == null:
		return
	player.debug_teleport(target)

# --- Free fly ---------------------------------------------------------------
## The body stays where you left it and stops simulating, so flying out and
## back is a look around rather than a move. On the host that also means the
## body it broadcasts to everyone else does not drift while you are up there.
func _set_flying(active: bool) -> void:
	if active == _flying:
		return
	var player := _local_player()
	if player == null:
		return
	_flying = active

	if _flying:
		_fly_camera.global_transform = player.get_node(^"Camera3D").global_transform
		_fly_yaw = player.rotation.y
		_fly_pitch = player.get_node(^"Camera3D").rotation.x
		_fly_velocity = Vector3.ZERO
		player.set_physics_process(false)
		player.set_process_unhandled_input(false)
		_fly_camera.current = true
	else:
		player.set_physics_process(true)
		player.set_process_unhandled_input(true)
		player.get_node(^"Camera3D").current = true

func _process(delta: float) -> void:
	_update_readout()
	if not _flying:
		return

	_fly_camera.rotation = Vector3(_fly_pitch, _fly_yaw, 0.0)

	var wish := Vector3(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(Config.KEY_FLY_UP))
			- float(Input.is_physical_key_pressed(Config.KEY_FLY_DOWN)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	)
	# Horizontal input is camera-relative, vertical is world-relative — looking
	# down should not turn "forward" into "into the pavement".
	var direction := Basis(Vector3.UP, _fly_yaw) * Vector3(wish.x, 0.0, wish.z)
	direction.y = wish.y
	if direction.length_squared() > 0.0:
		direction = direction.normalized()

	var speed := Config.FLY_SPEED
	if Input.is_physical_key_pressed(KEY_SHIFT):
		speed *= Config.FLY_SPRINT_MULTIPLIER
	_fly_velocity = _fly_velocity.lerp(
		direction * speed, clampf(Config.FLY_ACCELERATION * delta, 0.0, 1.0)
	)
	_fly_camera.global_position += _fly_velocity * delta

# --- Seed readout -----------------------------------------------------------
func _update_readout() -> void:
	if not _hud.visible:
		return
	var position := Vector3.ZERO
	if _flying:
		position = _fly_camera.global_position
	else:
		var player := _local_player()
		if player != null:
			position = player.global_position
	_readout.text = "seed %d (0x%x)   %s   x %.0f  z %.0f%s" % [
		Net.city_seed, Net.city_seed, _mode_name(), position.x, position.z,
		"   [flying]" if _flying else ""
	]

func _mode_name() -> String:
	match Net.mode:
		Net.Mode.HOST: return "host"
		Net.Mode.CLIENT: return "client"
		_: return "solo"

# --- Setup ------------------------------------------------------------------
func _build_hud() -> void:
	_hud = CanvasLayer.new()
	_hud.visible = Config.DEBUG_HUD_VISIBLE
	add_child(_hud)

	# Anchored by hand rather than by preset: a preset rewrites the offsets from
	# the label's current size, which is zero before it has any text.
	_readout = Label.new()
	_readout.anchor_left = 1.0
	_readout.anchor_right = 1.0
	_readout.offset_left = -640.0
	_readout.offset_right = -16.0
	_readout.offset_top = 12.0
	_readout.offset_bottom = 36.0
	_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_readout.modulate = Color(1, 1, 1, 0.75)
	_hud.add_child(_readout)

func _build_fly_camera() -> void:
	_fly_camera = Camera3D.new()
	_fly_camera.fov = Config.FOV
	_fly_camera.current = false
	add_child(_fly_camera)

func _local_player() -> Node:
	for child in players_root.get_children():
		if child.is_local:
			return child
	return null
