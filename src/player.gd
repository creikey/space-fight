extends RigidBody2D

const MOTION_SPEED = 500.0
const THRUST: float = 300.0

var health: float = 1.0
var controlling_peer: int = -1 # peer that will manage my input
var _puppet_transform : Transform2D = Transform2D(0.0, Vector2()) # set from the master
var _movement := Vector2() # only set and used on the network master

func _ready():
	$shape.disabled = not is_network_master()
#	set("motion/sync_to_physics", not is_network_master())

func _physics_process(delta):
	if controlling_peer == get_tree().get_network_unique_id(): # this node will manage input!
		var movement_to_transmit: Vector2 = Vector2(\
			float(Input.is_action_pressed("g_right")) - float(Input.is_action_pressed("g_left")),
			float(Input.is_action_pressed("g_down")) - float(Input.is_action_pressed("g_up"))
		)
#		printt("Transmitting movement ", movement_to_transmit)
		rpc_unreliable("receive_movement", movement_to_transmit)

	if is_network_master():
		applied_force = _movement * THRUST
#		printt("Moving with movement ", _movement)
#		move_and_slide(_movement*MOTION_SPEED)
		rpc_unreliable("receive_transform", global_transform, gamestate.frame)
#		rset_unreliable("puppet_position", global_position)
	else:
#	printt(global_transform, global_transform, 0.2)
		global_transform = global_transform.interpolate_with(_puppet_transform, 0.2)

var last_frame_received: int = 0

puppet func receive_transform(new_transform: Transform2D, frame: int):
	if frame > last_frame_received:
		_puppet_transform = new_transform
		last_frame_received = frame

master func receive_movement(new_movement: Vector2):
	if get_tree().get_rpc_sender_id() != controlling_peer:
		printerr("Warning: Somebody trying to send movement that isn't the controlling peer. Fishy!")
		return
#	printt("Setting to movement: ", new_movement)
	_movement = new_movement

func set_player_name(new_name):
	get_node("label").set_text(new_name)
