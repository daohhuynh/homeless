extends CharacterBody3D

## First-person walker. Keys are read as physical keycodes so the project
## needs no input map and WASD stays put on non-QWERTY layouts.

@onready var camera: Camera3D = $Camera3D

var _pitch := 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.position.y = Config.EYE_HEIGHT - Config.PLAYER_HEIGHT * 0.5
	camera.fov = Config.FOV

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * Config.MOUSE_SENSITIVITY)
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
	var grounded := is_on_floor()
	if not grounded:
		velocity.y -= Config.GRAVITY * delta
	elif Input.is_physical_key_pressed(KEY_SPACE):
		velocity.y = Config.JUMP_VELOCITY

	var input := Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	)
	var wish := (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()
	var sprinting := Input.is_physical_key_pressed(KEY_SHIFT)
	var speed := Config.SPRINT_SPEED if sprinting else Config.WALK_SPEED

	var control := 1.0 if grounded else Config.AIR_CONTROL
	var planar := Vector3(velocity.x, 0.0, velocity.z)
	if wish.length_squared() > 0.0:
		planar = planar.move_toward(wish * speed, Config.ACCELERATION * control * delta)
	else:
		planar = planar.move_toward(Vector3.ZERO, Config.FRICTION * control * delta)
	velocity.x = planar.x
	velocity.z = planar.z

	move_and_slide()

	var target_fov := Config.FOV + (Config.FOV_SPRINT_BONUS if sprinting and planar.length() > 1.0 else 0.0)
	camera.fov = lerpf(camera.fov, target_fov, Config.FOV_LERP_SPEED * delta)
