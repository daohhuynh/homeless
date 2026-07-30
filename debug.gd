extends Node

## Four debug tools, all bound in Config, all local-only:
##
##   T   teleport to a random street corner
##   F   toggle a free-fly camera that leaves your body behind
##   F3  toggle the seed readout
##   F2  type a note; it is appended to logs/session-<date>.log with the full
##       local game state at the moment you pressed the key
##
## Nothing here is a game mechanic and nothing here is authoritative. The one
## exception is the teleport, which has to tell the host where it went — the
## host simulates every body, so a client that moved only itself would be
## reconciled straight back to where it was standing.
##
## The note log records *this machine's* view, not the session's. That is the
## point: once tiredness corrupts perception per-client, two players writing a
## note about the same sign should produce two different log lines, and the log
## has to be able to show that.

@onready var city: Node3D = get_parent().get_node(^"City")
@onready var players_root: Node3D = get_parent().get_node(^"Players")

var _flying := false
var _fly_camera: Camera3D
var _fly_velocity := Vector3.ZERO
var _fly_yaw := 0.0
var _fly_pitch := 0.0

var _hud: CanvasLayer
var _readout: Label

## The note field lives on its own layer, so F3 hiding the readout cannot hide
## a field you are halfway through typing into.
var _note_layer: CanvasLayer
var _note_field: LineEdit
var _note_confirm: Label
var _note_open := false
var _note_mouse_was_captured := false
var _note_confirm_left := 0.0

func _ready() -> void:
	_build_hud()
	_build_note_field()
	_build_fly_camera()

# --- Keys -------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	# While the note field has focus it swallows every printable key, so none of
	# the other debug keys — or R/H/J in main.gd — can fire mid-sentence. Escape
	# is the exception: LineEdit does not consume it, so it lands here, and it
	# has to be caught before the player uses it to release the mouse.
	if _note_open:
		if event is InputEventKey and event.pressed and not event.echo \
				and event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_close_note()
		return

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
		Config.KEY_NOTE:
			get_viewport().set_input_as_handled()
			_open_note()

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
	if _note_confirm_left > 0.0:
		_note_confirm_left -= delta
		if _note_confirm_left <= 0.0:
			_note_confirm.visible = false
	# Free-fly movement polls Input directly, so without this a note typed while
	# flying would fly the camera through the city one letter at a time.
	if not _flying or _note_open:
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

# --- Session notes ----------------------------------------------------------
## F2 opens a one-line field. Enter writes the note plus the full local state to
## logs/session-<date>.log; Escape, or an empty note, writes nothing.
##
## The state is captured at submit rather than at open, because the useful
## reading of "I pressed F2 here" is where you were standing when you decided
## the thing was worth writing down, and typing does not move you: the player is
## frozen for the duration.
func _open_note() -> void:
	if _note_open:
		return
	_note_open = true
	_note_mouse_was_captured = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_note_confirm.visible = false
	_note_confirm_left = 0.0
	_note_field.text = ""
	_note_field.visible = true
	_note_field.grab_focus()
	_freeze_player(true)

func _close_note() -> void:
	if not _note_open:
		return
	_note_open = false
	_note_field.release_focus()
	_note_field.visible = false
	_freeze_player(false)
	if _note_mouse_was_captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_note_submitted(text: String) -> void:
	var note := text.strip_edges()
	_close_note()
	if note.is_empty():
		return
	var path := _write_entry(note)
	if path.is_empty():
		return
	_note_confirm.text = "note written to %s" % path
	_note_confirm.visible = true
	_note_confirm_left = Config.NOTE_CONFIRM_SECONDS

## Frozen the same way free-fly freezes it, and for the same reason: the body
## must not drift while its owner is doing something else. Skipped entirely when
## flying, because the body is already stopped and unfreezing it here would put
## it back under simulation while the camera is still airborne.
func _freeze_player(frozen: bool) -> void:
	if _flying:
		return
	var player := _local_player()
	if player == null:
		return
	player.set_physics_process(not frozen)
	player.set_process_unhandled_input(not frozen)

# --- Writing the log --------------------------------------------------------
## Returns the path written, or "" if it could not be opened.
func _write_entry(note: String) -> String:
	var dir := ProjectSettings.globalize_path(Config.NOTE_LOG_DIR)
	DirAccess.make_dir_recursive_absolute(dir)
	var path := "%s/session-%s.log" % [Config.NOTE_LOG_DIR, Time.get_date_string_from_system()]

	var entry := "\n".join(_state_lines(note)) + "\n"

	# FileAccess has no append mode. READ_WRITE keeps the existing file and
	# seek_end puts us after it; WRITE is only for the first note of the day,
	# because on a missing file READ_WRITE fails rather than creating one.
	var file := FileAccess.open(path, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(path, FileAccess.WRITE)
	else:
		file.seek_end()
	if file == null:
		push_error("could not open %s: %s" % [path, error_string(FileAccess.get_open_error())])
		return ""
	file.store_string(entry)
	file.close()

	# Also to stdout, so a note is still recoverable from the terminal if the
	# session dies before anyone reads the file.
	print(entry.strip_edges())
	return path

func _state_lines(note: String) -> Array[String]:
	var position := _eye_position()
	return [
		"--- %s  %s" % [Time.get_time_string_from_system(), _clock_state()],
		"note: %s" % note,
		"seed: %d (0x%x)" % [Net.city_seed, Net.city_seed],
		"who: %s, peer %d" % [_mode_name(), Net.self_id()],
		"pos: x %.1f  y %.1f  z %.1f  facing %.0f deg%s" % [
			position.x, position.y, position.z,
			rad_to_deg(_facing()), "  [flying]" if _flying else ""
		],
		"tiredness: %s" % _tiredness_state(),
		"visible: %s" % _visible_locations(position),
		"discovered: %s" % _discovered_state(),
		"",
	]

## Where the note was taken from, which is the camera rather than the body when
## flying — a note written from 200m up is about what you could see up there.
func _eye_position() -> Vector3:
	if _flying:
		return _fly_camera.global_position
	var player := _local_player()
	if player == null:
		return Vector3.ZERO
	return player.get_node(^"Camera3D").global_position

func _facing() -> float:
	if _flying:
		return _fly_yaw
	var player := _local_player()
	return 0.0 if player == null else player.rotation.y

## Named locations whose sign is currently drawing and in frame, nearest first.
## No occlusion test: a landmark behind a tower still counts. The line answers
## "what was on screen", and one raycast per landmark against boxes this large
## would mostly report that the city has buildings in it.
func _visible_locations(from: Vector3) -> String:
	if not city.is_built:
		return "(no city)"
	var camera := _active_camera()
	if camera == null:
		return Config.NOTE_MISSING

	var seen: Array[Dictionary] = []
	for landmark in city.landmarks():
		var origin: Vector3 = landmark["position"]
		var distance := Vector2(origin.x - from.x, origin.z - from.z).length()
		if distance > Config.NOTE_VISIBLE_RANGE:
			continue
		# Test the sign, not the footprint: the sign is the thing you read, and
		# it sits above the roof where a nearby building is less likely to cover
		# it than it would the door.
		var sign_point := origin + Vector3.UP * (
			float(landmark["height"]) + Config.LABEL_HEIGHT_ABOVE_ROOF
		)
		if not camera.is_position_in_frustum(sign_point):
			continue
		seen.append({"text": "%s (%s, %dm)" % [
			landmark["name"], landmark["kind"], roundi(distance)
		], "distance": distance})
	if seen.is_empty():
		return "(nothing named in frame)"
	seen.sort_custom(func(a, b): return a["distance"] < b["distance"])

	var parts: Array[String] = []
	for item in seen:
		parts.append(item["text"])
	return ", ".join(parts)

func _active_camera() -> Camera3D:
	if _flying:
		return _fly_camera
	var player := _local_player()
	return null if player == null else player.get_node(^"Camera3D") as Camera3D

# --- Systems that do not exist yet ------------------------------------------
## Day, time of day, tiredness and discovery are all still ahead on the build
## order. Each is read through a soft lookup against the shape it will have, so
## the log starts recording it the day it lands rather than the day someone
## remembers this file exists. Until then every one of them writes
## Config.NOTE_MISSING and says why, so an entry is never quietly incomplete.
##
## The contracts assumed here, and the things to change if they end up different:
##   /root/Clock          day: int, time_of_day: float in 0..1
##   local player         tiredness_tier: anything printable
##   /root/Discovery      discovered_names() -> Array
func _clock_state() -> String:
	var clock := get_node_or_null(^"/root/Clock")
	if clock == null or not (&"day" in clock and &"time_of_day" in clock):
		return "day %s  time %s (no clock yet)" % [Config.NOTE_MISSING, Config.NOTE_MISSING]
	var minutes := int(round(float(clock.time_of_day) * 24.0 * 60.0)) % 1440
	return "day %d  time %02d:%02d" % [int(clock.day), minutes / 60, minutes % 60]

func _tiredness_state() -> String:
	var player := _local_player()
	if player == null or not (&"tiredness_tier" in player):
		return "%s (no tiredness system yet)" % Config.NOTE_MISSING
	return str(player.tiredness_tier)

func _discovered_state() -> String:
	var registry := get_node_or_null(^"/root/Discovery")
	if registry == null or not registry.has_method(&"discovered_names"):
		return "%s (no discovery system yet)" % Config.NOTE_MISSING
	var names: Array = registry.discovered_names()
	if names.is_empty():
		return "(nothing yet)"
	return ", ".join(names)

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

func _build_note_field() -> void:
	_note_layer = CanvasLayer.new()
	add_child(_note_layer)

	_note_field = LineEdit.new()
	_note_field.visible = false
	_note_field.placeholder_text = "note (Enter to log, Escape to cancel)"
	_note_field.max_length = Config.NOTE_MAX_LENGTH
	_note_field.anchor_left = 0.0
	_note_field.anchor_right = 1.0
	_note_field.anchor_top = 1.0
	_note_field.anchor_bottom = 1.0
	_note_field.offset_left = 16.0
	_note_field.offset_right = -16.0
	_note_field.offset_top = -52.0
	_note_field.offset_bottom = -20.0
	_note_field.text_submitted.connect(_on_note_submitted)
	_note_layer.add_child(_note_field)

	_note_confirm = Label.new()
	_note_confirm.visible = false
	_note_confirm.anchor_top = 1.0
	_note_confirm.anchor_bottom = 1.0
	_note_confirm.offset_left = 16.0
	_note_confirm.offset_right = 640.0
	_note_confirm.offset_top = -80.0
	_note_confirm.offset_bottom = -56.0
	_note_confirm.modulate = Color(1, 1, 1, 0.75)
	_note_layer.add_child(_note_confirm)

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
