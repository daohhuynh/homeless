extends CharacterBody3D

## Movement is host-authoritative: clients send intent, the host runs the
## actual CharacterBody3D simulation for every player and broadcasts the
## result. A client also simulates its own player locally as a prediction so
## input feels instant, then blends toward the host's version.
##
## Look direction is the exception — yaw is applied locally the moment the
## mouse moves and merely reported to the host. A camera that waits on a round
## trip is unusable, and there is nothing to cheat by turning early.

var peer_id := 1
var is_local := false

@onready var camera: Camera3D = $Camera3D
@onready var body: MeshInstance3D = $Body
@onready var name_tag: Label3D = $NameTag

# Intent, replicated from client to host.
var _wish := Vector2.ZERO
var _yaw := 0.0
var _sprint := false
var _jump := false

# Last authoritative state received from the host.
var _net_position := Vector3.ZERO
var _net_yaw := 0.0
var _has_net_state := false

var _pitch := 0.0

func _ready() -> void:
	_yaw = rotation.y
	_net_position = global_position
	_net_yaw = _yaw

	name_tag.text = "Player %d" % peer_id
	name_tag.font_size = Config.NAME_TAG_FONT_SIZE
	name_tag.pixel_size = Config.NAME_TAG_PIXEL_SIZE
	name_tag.position.y = Config.NAME_TAG_HEIGHT
	name_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_tag.visibility_range_end = Config.NAME_TAG_RANGE
	name_tag.visibility_range_end_margin = Config.NAME_TAG_RANGE * 0.2

	var mat := StandardMaterial3D.new()
	mat.albedo_color = _color()
	body.material_override = mat

	camera.current = is_local
	if is_local:
		camera.position.y = Config.EYE_HEIGHT - Config.PLAYER_HEIGHT * 0.5
		camera.fov = Config.FOV
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		# You are inside your own capsule; rendering it fills the screen.
		body.visible = false
		name_tag.visible = false

func _color() -> Color:
	var index: int = maxi(Net.player_ids.find(peer_id), 0)
	return Config.PLAYER_COLORS[index % Config.PLAYER_COLORS.size()]

func _unhandled_input(event: InputEvent) -> void:
	if not is_local:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw = wrapf(_yaw - event.relative.x * Config.MOUSE_SENSITIVITY, -PI, PI)
		_pitch = clampf(
			_pitch - event.relative.y * Config.MOUSE_SENSITIVITY,
			-Config.PITCH_LIMIT, Config.PITCH_LIMIT
		)
		camera.rotation.x = _pitch
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed(&"ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	if is_local:
		_gather_input()
		rotation.y = _yaw
		if Net.is_active_client():
			_submit_input.rpc_id(1, _wish, _yaw, _sprint, _jump)

	# The host simulates everyone. A client simulates only itself, as a
	# prediction, and interpolates the others from host state.
	if Net.is_host() or is_local:
		_simulate(delta)
	if not Net.is_host() and _has_net_state:
		if is_local:
			_reconcile(delta)
		else:
			_interpolate(delta)

	if is_local:
		var moving := Vector3(velocity.x, 0.0, velocity.z).length() > 1.0
		var target_fov := Config.FOV + (Config.FOV_SPRINT_BONUS if _sprint and moving else 0.0)
		camera.fov = lerpf(camera.fov, target_fov, Config.FOV_LERP_SPEED * delta)

func _gather_input() -> void:
	_wish = Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	)
	_sprint = Input.is_physical_key_pressed(KEY_SHIFT)
	# Held rather than edge-triggered, so a dropped packet cannot eat a jump.
	_jump = Input.is_physical_key_pressed(KEY_SPACE)

## Client -> host intent. Unreliable: a lost packet is one stale tick, and the
## next one supersedes it anyway.
@rpc("any_peer", "unreliable_ordered")
func _submit_input(wish: Vector2, yaw: float, sprint: bool, jump: bool) -> void:
	if not multiplayer.is_server():
		return
	# A peer may only drive its own player.
	if multiplayer.get_remote_sender_id() != peer_id:
		return
	_wish = wish
	_yaw = yaw
	_sprint = sprint
	_jump = jump
	rotation.y = yaw

func _simulate(delta: float) -> void:
	var grounded := is_on_floor()
	if not grounded:
		velocity.y -= Config.GRAVITY * delta
	elif _jump:
		velocity.y = Config.JUMP_VELOCITY

	var basis_yaw := Basis(Vector3.UP, _yaw)
	var direction := (basis_yaw * Vector3(_wish.x, 0.0, _wish.y)).normalized()
	var speed := Config.SPRINT_SPEED if _sprint else Config.WALK_SPEED
	var control := 1.0 if grounded else Config.AIR_CONTROL

	var planar := Vector3(velocity.x, 0.0, velocity.z)
	if direction.length_squared() > 0.0:
		planar = planar.move_toward(direction * speed, Config.ACCELERATION * control * delta)
	else:
		planar = planar.move_toward(Vector3.ZERO, Config.FRICTION * control * delta)
	velocity.x = planar.x
	velocity.z = planar.z

	move_and_slide()

## Pull the local prediction back toward the host's version.
func _reconcile(delta: float) -> void:
	if global_position.distance_to(_net_position) > Config.NET_SNAP_DISTANCE:
		global_position = _net_position
		return
	global_position = global_position.lerp(
		_net_position, clampf(Config.NET_CORRECTION_RATE * delta, 0.0, 1.0)
	)

## Remote players are pure playback of host state, smoothed between packets.
func _interpolate(delta: float) -> void:
	var weight := clampf(Config.NET_INTERP_RATE * delta, 0.0, 1.0)
	if global_position.distance_to(_net_position) > Config.NET_SNAP_DISTANCE:
		global_position = _net_position
		rotation.y = _net_yaw
		return
	global_position = global_position.lerp(_net_position, weight)
	rotation.y = lerp_angle(rotation.y, _net_yaw, weight)

# --- Debug ------------------------------------------------------------------
## Move now, locally, so the key feels instant; then tell the host, because the
## host owns this body and would otherwise reconcile the move away within a few
## frames. The prediction target is moved too, or the reconcile drags us back
## across the city until the next state packet lands.
func debug_teleport(target: Vector3) -> void:
	if not is_local:
		return
	global_position = target
	velocity = Vector3.ZERO
	_net_position = target
	if Net.is_active_client():
		_accept_teleport.rpc_id(1, target)

@rpc("any_peer", "reliable")
func _accept_teleport(target: Vector3) -> void:
	if not multiplayer.is_server():
		return
	# A peer may only move its own player. Debug tools are still tools.
	if multiplayer.get_remote_sender_id() != peer_id:
		return
	global_position = target
	velocity = Vector3.ZERO

func apply_net_state(net_position: Vector3, net_yaw: float) -> void:
	_net_position = net_position
	_net_yaw = net_yaw
	_has_net_state = true
