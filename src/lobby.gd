extends Control

const TARGET_IP: String = "wss://signalserve.ddns.net"

onready var _connect_panel: Panel = $Connect
onready var _menu_vbox: VBoxContainer = _connect_panel.get_node("CenterContainer/V")
onready var _name_label: Label = _menu_vbox.get_node("NameLabel")
onready var _name_input: LineEdit = _menu_vbox.get_node("NameInput")
onready var _host_button: Button = _menu_vbox.get_node("Host")
onready var _joining_hbox: HBoxContainer = _menu_vbox.get_node("H")
onready var _lobby_code_input: LineEdit = _joining_hbox.get_node("LobbyCode")
onready var _lobby_join_button: Button = _joining_hbox.get_node("Join")
onready var _error_label: Label = _menu_vbox.get_node("ErrorLabel")

func _ready():
	if OS.get_name() == 'HTML5':
		$connect/server.hide()
	# Called every time the node is added to the scene.
	gamestate.connect("connection_failed", self, "_on_connection_failed")
	gamestate.connect("connection_succeeded", self, "_on_connection_success")
	gamestate.connect("player_list_changed", self, "refresh_lobby")
	gamestate.connect("lobby_joined", self, "_update_lobby")
	gamestate.connect("game_ended", self, "_on_game_ended")
	gamestate.connect("game_error", self, "_on_game_error")
	if OS.get_name() == 'HTML5':
		var data = JavaScript.eval("(new URLSearchParams(window.location.hash.replace('#', '', 1))).get('lobby')")
		if typeof(data) == TYPE_STRING:
			$connect/lobby.text = data

func _update_lobby(text):
	printt("Window parent location: ", JavaScript.eval("window.location"))
	if OS.get_name() == 'HTML5':
		JavaScript.eval("var x = new URLSearchParams(window.location.hash.replace('#', '', 1)); x.set('lobby', '" + text + "'); window.location.hash = x.toString()")
	$Players/lobby.text = text

func _on_host_pressed():
	if _name_input.text == "":
		_error_label.text = "Invalid name!"
		return

	get_node("Connect").hide()
	
	get_node("Players").show()
	_error_label.text = ""

	var player_name = _name_input.text
	gamestate.host_game(player_name, TARGET_IP)
	# refresh_lobby() gets called by the player_list_changed signal, emitted when host is ready

func _on_join_pressed():
	if _name_input.text == "":
		_error_label.text = "Invalid name!"

	var lobby = _lobby_code_input.text
	if lobby == '':
		_error_label.text = "Must specify a lobby when joining!"
		return
	_error_label.text=""
	_host_button.disabled = true
	_lobby_join_button.disabled = true

	var player_name = _name_input.text
	gamestate.join_game(TARGET_IP, player_name, lobby)
	# refresh_lobby() gets called by the player_list_changed signal

func _on_connection_success():
	get_node("Connect").hide()
	get_node("Players").show()

func _on_connection_failed():
	_host_button.disabled = false
	_lobby_join_button.disabled = false
	_error_label.set_text("Connection failed.")

func _on_game_ended():
	show()
	get_node("Connect").show()
	get_node("Players").hide()
	_host_button.disabled = false
	_lobby_join_button.disabled = false
	if OS.get_name() == 'HTML5':
		JavaScript.eval("var x = new URLSearchParams(window.location.hash.replace('#', '', 1)); x.delete('lobby'); window.location.hash = x.toString()")
	$Players/lobby.text = ''
	$connect/lobby.text = ''

func _on_game_error(errtxt):
	get_node("error").dialog_text = errtxt
	get_node("error").popup_centered_minsize()

func refresh_lobby():
	var players = gamestate.get_player_list()
	players.sort()
	get_node("Players/list").clear()
	get_node("Players/list").add_item(gamestate.get_player_name() + " (You)")
	for p in players:
		get_node("Players/list").add_item(p)

	get_node("Players/start").disabled = not get_tree().is_network_server()

func _on_start_pressed():
	gamestate.begin_game()

func _on_server_toggled(button_pressed):
	pass
#	if button_pressed:
#		Server.listen(9080)
#		$connect/server.text = "Stop"
#	else:
#		Server.stop()
#		$connect/server.text = "Listen"
