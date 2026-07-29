extends Node

## Session state: who is connected and which city everyone is walking around.
## The host owns both. A client builds nothing until the host has told it the
## seed, so the two never disagree about the map.

signal world_ready       ## Seed is known; the city may be built.
signal players_changed   ## player_ids was replaced.
signal net_status(text: String)

## Tracked explicitly rather than inferred from the MultiplayerAPI: Godot
## installs an OfflineMultiplayerPeer by default, which is non-null and
## reports itself as connected, so "is there a peer?" is always true and
## cannot distinguish solo play from a real session.
enum Mode { SOLO, HOST, CLIENT }

var mode := Mode.SOLO
var city_seed: int = 0
var player_ids: Array[int] = []
var started := false

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

# --- Authority helpers ------------------------------------------------------
## Solo play counts as hosting: no peers, and we are in charge.
func is_host() -> bool:
	return mode != Mode.CLIENT

func is_networked() -> bool:
	return mode != Mode.SOLO

## True only once the ENet handshake has finished. Calling an RPC before that
## — or after the host drops — errors, and the local player keeps simulating
## through both windows.
func is_active_client() -> bool:
	if mode != Mode.CLIENT:
		return false
	var peer := multiplayer.multiplayer_peer
	return peer != null \
		and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED

## Querying a dropped peer errors, so fall back to the solo id.
func self_id() -> int:
	if mode == Mode.SOLO:
		return 1
	return multiplayer.get_unique_id()

# --- Starting a session -----------------------------------------------------
func start_solo() -> void:
	mode = Mode.SOLO
	city_seed = randi()
	player_ids = [1]
	started = true
	net_status.emit("Solo")
	world_ready.emit()
	players_changed.emit()

func host() -> bool:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(Config.NET_PORT, Config.MAX_PLAYERS)
	if err != OK:
		net_status.emit("Host failed on port %d: %s" % [Config.NET_PORT, error_string(err)])
		return false
	multiplayer.multiplayer_peer = peer
	mode = Mode.HOST
	city_seed = randi()
	player_ids = [1]
	started = true
	net_status.emit("Hosting on port %d" % Config.NET_PORT)
	world_ready.emit()
	players_changed.emit()
	return true

func join(address: String = Config.NET_DEFAULT_ADDRESS) -> bool:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, Config.NET_PORT)
	if err != OK:
		net_status.emit("Join failed: %s" % error_string(err))
		return false
	multiplayer.multiplayer_peer = peer
	mode = Mode.CLIENT
	net_status.emit("Connecting to %s:%d..." % [address, Config.NET_PORT])
	return true

func disconnect_session() -> void:
	if mode != Mode.SOLO and multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	mode = Mode.SOLO
	started = false
	player_ids.clear()

# --- Host: membership -------------------------------------------------------
func _on_peer_connected(id: int) -> void:
	if not multiplayer.is_server():
		return
	if not player_ids.has(id):
		player_ids.append(id)
	# World first (reliable, so it lands before any state that assumes it).
	_receive_world.rpc_id(id, city_seed, player_ids)
	_receive_players.rpc(player_ids)
	net_status.emit("Hosting — %d player(s)" % player_ids.size())
	players_changed.emit()

func _on_peer_disconnected(id: int) -> void:
	if not multiplayer.is_server():
		return
	player_ids.erase(id)
	_receive_players.rpc(player_ids)
	net_status.emit("Hosting — %d player(s)" % player_ids.size())
	players_changed.emit()

# --- Client: handshake ------------------------------------------------------
func _on_connected_to_server() -> void:
	net_status.emit("Connected, waiting for city...")

func _on_connection_failed() -> void:
	net_status.emit("Connection failed — is the host running?")
	disconnect_session()

func _on_server_disconnected() -> void:
	net_status.emit("Host disconnected")
	disconnect_session()

@rpc("authority", "reliable")
func _receive_world(seed_value: int, ids: Array) -> void:
	city_seed = seed_value
	player_ids = _as_int_array(ids)
	started = true
	net_status.emit("Joined — %d player(s)" % player_ids.size())
	world_ready.emit()
	players_changed.emit()

@rpc("authority", "reliable")
func _receive_players(ids: Array) -> void:
	player_ids = _as_int_array(ids)
	if started:
		net_status.emit("Joined — %d player(s)" % player_ids.size())
	players_changed.emit()

# --- Reshuffle (host only) --------------------------------------------------
func request_reshuffle() -> void:
	if not is_host():
		return
	city_seed = randi()
	if is_networked():
		_reload_world.rpc(city_seed)
	else:
		_reload_world(city_seed)

@rpc("authority", "call_local", "reliable")
func _reload_world(seed_value: int) -> void:
	city_seed = seed_value
	get_tree().call_deferred(&"reload_current_scene")

## RPC'd arrays arrive untyped; player_ids stays Array[int].
func _as_int_array(ids: Array) -> Array[int]:
	var out: Array[int] = []
	for id in ids:
		out.append(int(id))
	return out
