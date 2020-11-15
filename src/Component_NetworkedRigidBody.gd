extends Node

class_name Component_NetworkedRigidBody

onready var to_control: RigidBody2D = get_parent()


var last_frame_received: int = 0
var _puppet_transform : Transform2D = Transform2D(0.0, Vector2()) # set from the master

puppet func receive_transform(new_transform: Transform2D, frame: int):
	if frame > last_frame_received:
		_puppet_transform = new_transform
		last_frame_received = frame

func _physics_process(delta):
	if is_network_master():
		rpc_unreliable("receive_transform", to_control.global_transform, gamestate.frame)
	else:
#	printt(global_transform, global_transform, 0.2)
		to_control.global_transform = to_control.global_transform.interpolate_with(_puppet_transform, 0.2)
