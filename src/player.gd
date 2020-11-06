extends KinematicBody2D

const MOTION_SPEED = 500.0

var controlling_peer: int = -1 # peer that will manage my input

puppet var puppet_position := Vector2() # set from the master
var _movement := Vector2() # only set and used on the network master

func _physics_process(delta):
	if controlling_peer == get_tree().get_network_unique_id(): # this node will manage input!
		var movement_to_transmit: Vector2 = Vector2(\
			float(Input.is_action_pressed("g_right")) - float(Input.is_action_pressed("g_left")),
			float(Input.is_action_pressed("g_down")) - float(Input.is_action_pressed("g_up"))
		)
#		printt("Transmitting movement ", movement_to_transmit)
		rpc_unreliable("receive_movement", movement_to_transmit)

	if is_network_master():
#		printt("Moving with movement ", _movement)
		move_and_slide(_movement*MOTION_SPEED)
		rset_unreliable("puppet_position", global_position)
	else:
		global_position = puppet_position

master func receive_movement(new_movement: Vector2):
	if get_tree().get_rpc_sender_id() != controlling_peer:
		printerr("Warning: Somebody trying to send movement that isn't the controlling peer. Fishy!")
		return
#	printt("Setting to movement: ", new_movement)
	_movement = new_movement

func set_player_name(new_name):
	get_node("label").set_text(new_name)
