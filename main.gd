extends Node3D

## Session shell: starts solo/host/client, keeps the Players container matching
## Net.player_ids, and (on the host) broadcasts authoritative player state.

const PLAYER_SCENE := preload("res://player.tscn")

@onready var city: Node3D = $City
@onready var players_root: Node3D = $Players
@onready var status_label: Label = $HUD/Status

var _sync_accum := 0.0

func _ready() -> void:
	Net.world_ready.connect(_on_world_ready)
	Net.players_changed.connect(_sync_players)
	Net.net_status.connect(_set_status)

	# After a reshuffle the scene reloads but the session survives in Net.
	if Net.started:
		_on_world_ready()
	else:
		_start_from_command_line()

func _start_from_command_line() -> void:
	var args := OS.get_cmdline_user_args()
	for arg in args:
		if arg == "--host":
			Net.host()
			return
		if arg.begins_with("--join"):
			var address := Config.NET_DEFAULT_ADDRESS
			if arg.contains("="):
				address = arg.split("=", true, 1)[1]
			Net.join(address)
			return
	Net.start_solo()

func _on_world_ready() -> void:
	# Peer ids change when a session starts, so no existing player node can be
	# trusted to still mean what it did (a solo "1" is the host after joining).
	_clear_players()
	city.build(Net.city_seed)
	_sync_players()

func _clear_players() -> void:
	for child in players_root.get_children():
		_drop(child)

## Detach immediately, then free. queue_free() alone leaves the node in the
## tree for the rest of the frame, which blocks re-adding the same name.
func _drop(node: Node) -> void:
	players_root.remove_child(node)
	node.queue_free()

func _set_status(text: String) -> void:
	status_label.text = text

# --- Player container -------------------------------------------------------
## Net.player_ids is the single source of truth; this just makes the scene
## tree match it.
func _sync_players() -> void:
	if not Net.started or not city.is_built:
		return

	for child in players_root.get_children():
		if not Net.player_ids.has(child.peer_id):
			_drop(child)

	for id in Net.player_ids:
		if players_root.has_node(NodePath(str(id))):
			continue
		var player := PLAYER_SCENE.instantiate()
		player.name = str(id)
		player.peer_id = id
		player.is_local = (id == Net.self_id())
		players_root.add_child(player)
		# Only the host places anyone; clients receive positions.
		if Net.is_host():
			player.global_position = city.spawn_point(Net.player_ids.find(id))

# --- Host -> clients: authoritative state -----------------------------------
func _physics_process(delta: float) -> void:
	if not Net.is_networked() or not Net.is_host():
		return
	_sync_accum += delta
	var interval := 1.0 / Config.NET_SYNC_HZ
	if _sync_accum < interval:
		return
	_sync_accum = 0.0

	var state := {}
	for player in players_root.get_children():
		state[player.peer_id] = [player.global_position, player.rotation.y]
	if not state.is_empty():
		_apply_state.rpc(state)

@rpc("authority", "unreliable_ordered")
func _apply_state(state: Dictionary) -> void:
	for id in state:
		var player := players_root.get_node_or_null(NodePath(str(id)))
		if player != null:
			player.apply_net_state(state[id][0], state[id][1])

# --- Session keys -----------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		Config.KEY_RESHUFFLE:
			# Host-authoritative: a client asking would desync the city.
			if Net.is_host():
				get_viewport().set_input_as_handled()
				Net.request_reshuffle()
		Config.KEY_HOST:
			if not Net.is_networked():
				get_viewport().set_input_as_handled()
				Net.host()  # emits world_ready, which rebuilds the world
		Config.KEY_JOIN:
			if not Net.is_networked():
				get_viewport().set_input_as_handled()
				Net.started = false
				Net.join(Config.NET_DEFAULT_ADDRESS)
