extends Node

const VERSION: int = 3

# Name for my player
var player_data = {
	"username": "The Warrior",
	"team": 0,
	"version": VERSION,
}

const TEAM_ID_TO_NAME: Dictionary = {
	0: "Team A",
	1: "Team B",
}

# Names for remote players in id:name format
var players = {}
var frame: int = -1

var team_scores: Dictionary = {
	"team_a": 0,
	"team_b": 0,
}

var dead_body_counter: int = 1

# Signals to let lobby GUI know what's going on
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)
signal lobby_joined(lobby)

# Callback from SceneTree
func _player_connected(_id):
	# This is not used in this demo, because _connected_ok is called for clients
	# on success and will do the job.
	pass

# Callback from SceneTree
func _player_disconnected(id):
	if get_tree().is_network_server():
		if has_node("/root/world"): # Game is in progress
			emit_signal("game_error", "Player " + players[id]["username"] + " disconnected")
			end_game()
		else: # Game is not in progress
			# If we are the server, send to the new dude all the already registered players
			unregister_player(id)
			for p_id in players:
				# Erase in the server
				rpc_id(p_id, "unregister_player", id)

# Callback from SceneTree, only for clients (not server)
func _connected_ok():
	# Registration of a client beings here, tell everyone that we are here
	broadcast_my_info()
	emit_signal("connection_succeeded")

func broadcast_my_info():
	rpc("register_player", get_tree().get_network_unique_id(), player_data)
	emit_signal("player_list_changed")

# Callback from SceneTree, only for clients (not server)
func _server_disconnected():
	emit_signal("game_error", "Server disconnected")
	end_game()

# Callback from SceneTree, only for clients (not server)
func _connected_fail():
	get_tree().set_network_peer(null) # Remove peer
	emit_signal("connection_failed")

func _get_player_data(id: int) -> Dictionary: # will always return correct even if id is self
	if id == get_tree().get_network_unique_id():
		return player_data
	else:
		return players[id]

# Lobby management functions

remote func register_player(id: int, new_player_data: Dictionary):
	if get_tree().is_network_server():
		# If we are the server, let everyone know about the new player
		rpc_id(id, "register_player", 1, player_data) # Send myself to new dude
		for p_id in players: # Then, for each remote player
			rpc_id(id, "register_player", p_id, players[p_id]) # Send player to new dude
			rpc_id(p_id, "register_player", id, new_player_data) # Send new dude to player

	if id != get_tree().get_network_unique_id(): # not sure why it can be the same
		players[id] = new_player_data
	emit_signal("player_list_changed")

remote func unregister_player(id):
	players.erase(id)
	emit_signal("player_list_changed")

remote func pre_start_game(spawn_points):
	for p in players:
		var cur_version: int = players[p]["version"]
		var message: String = ""
		if cur_version < VERSION:
			message = str("Player ", players[p]["username"], " has an out of date game version!")
		elif cur_version > VERSION:
			message = str("Player ", players[p]["username"], " has too updated of a game version!")
		
		if message != "":
			emit_signal("game_error", message)
			end_game()
			
	
	# Change scene
	var world = load("res://world.tscn").instance()
	get_tree().get_root().add_child(world)

	get_tree().get_root().get_node("Lobby").hide()

	var player_scene = load("res://player.tscn")

	for p_id in spawn_points:
		# gets the team's set of spawn points, then spawn point index from dict
		var spawn_pos: Vector2 = world.get_node(\
			str("Team", _get_player_data(p_id)["team"], "SpawnPoints", \
			"/", spawn_points[p_id])\
		).global_position
#		var spawn_pos = world.get_node("spawn_points/" + str(spawn_points[p_id])).position
		var player = player_scene.instance()

		player.spawn_transform = Transform2D(0.0, spawn_pos)
		player.set_name(str(p_id)) # Use unique ID as node name
		player.set_deferred("global_position", spawn_pos)
		player.set_network_master(1) #set server as master
#		player.set_network_master(p_id) #set unique id as master

		player.set_player_name(_get_player_data(p_id)["username"])

		world.get_node("players").add_child(player)

		player.controlling_peer = p_id

		if p_id == get_tree().get_network_unique_id():
#			player.is_current_player = true
			world.get_node("WorldCamera").target = player


	# Set up score
	world.get_node("score").add_player(get_tree().get_network_unique_id(), player_data["username"])
	for pn in players:
		world.get_node("score").add_player(pn, players[pn]["username"])
	
	for team_name in team_scores:
		team_scores[team_name] = 0

	if not get_tree().is_network_server():
		# Tell server we are ready to start
		rpc_id(1, "ready_to_start", get_tree().get_network_unique_id())
	elif players.size() == 0:
		post_start_game()

puppetsync func modify_team_score(team_name: String, delta: int):
	team_scores[team_name] += delta

remote func post_start_game():
	get_tree().set_pause(false) # Unpause and unleash the game!
	frame = 0 # this will 

var players_ready = []

remote func ready_to_start(id):
	assert(get_tree().is_network_server())

	if not id in players_ready:
		players_ready.append(id)

	if players_ready.size() == players.size():
		for p in players:
			rpc_id(p, "post_start_game")
		post_start_game()

func host_game(new_player_name, ip):
	player_data["username"] = new_player_name
	Client.start(ip)

func join_game(ip, new_player_name, lobby):
	player_data["username"] = new_player_name
	Client.start(ip, lobby)

func _signaling_disconnected():
	if not Client.sealed: # Game has not started yet
		emit_signal("game_error", "Signaling server disconnected:\n%d: %s" % [Client.code, Client.reason])
		end_game()

func _signaling_inited(lobby):
	get_tree().set_network_peer(Client.rtc_mp)
	emit_signal("lobby_joined", lobby)
	emit_signal("player_list_changed")

# returns list of player data
func get_player_list() -> Array:
	return players.values()

func get_player_name():
	return player_data["username"]

func begin_game():
	assert(get_tree().is_network_server())

	Client.seal_lobby()
	# Create a dictionary with peer id and respective spawn points, could be improved by randomizing
	var spawn_points = {}
	
	# reset count of players spawned in team to zero
	var team_id_to_spawn_point_index = TEAM_ID_TO_NAME.duplicate(true)
	for team_id in team_id_to_spawn_point_index.keys():
		team_id_to_spawn_point_index[team_id] = 0
	
	spawn_points[1] = 0 # Server in spawn point 0
	team_id_to_spawn_point_index[player_data["team"]] += 1
	
	for p in players:
		var cur_team_id: int = players[p]["team"]
		spawn_points[p] = team_id_to_spawn_point_index[cur_team_id]
		team_id_to_spawn_point_index[cur_team_id] += 1
	# Call to pre-start game with the spawn points
	for p in players:
		rpc_id(p, "pre_start_game", spawn_points)

	printt("Spawn points: ", var2str(spawn_points))

	pre_start_game(spawn_points)

func in_game() -> bool:
	return has_node("/root/world")

func end_game():
	if has_node("/root/world"): # Game is in progress
		# End it
		get_node("/root/world").queue_free()

	emit_signal("game_ended")
	players.clear()
	get_tree().set_network_peer(null) # End networking
	Client.stop()

func _physics_process(_delta):
	if frame >= 0:
		frame += 1

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")

	Client.connect("lobby_joined", self, "_signaling_inited")
	Client.connect("disconnected", self, "_signaling_disconnected")
