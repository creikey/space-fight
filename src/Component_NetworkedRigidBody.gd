extends Node

class_name Component_NetworkedRigidBody

export var conserve_packets: bool = false

onready var to_control: RigidBody2D = get_parent()


var last_frame_received: int = 0
var puppet_transform : Transform2D = Transform2D(0.0, Vector2()) # set from the master

puppet func receive_transform(new_transform: Transform2D, frame: int):
	if frame > last_frame_received:
		puppet_transform = new_transform
		last_frame_received = frame

func _physics_process(delta):
	if is_network_master():
		var send_transform: bool = true
		if conserve_packets:
			var speed: float = to_control.linear_velocity.length()
			if speed < 10.0 and speed > 0.01:
				to_control.linear_velocity = Vector2()
				to_control.angular_velocity = 0.0
			send_transform = to_control.linear_velocity.length() > 0.01
		if send_transform:
			rpc_unreliable("receive_transform", to_control.global_transform, gamestate.frame)
	else:
#	printt(global_transform, global_transform, 0.2)
		to_control.global_transform = to_control.global_transform.interpolate_with(puppet_transform, 0.2)
