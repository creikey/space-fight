extends RigidBody2D

class_name DeadBody

func create_from_state(state: Dictionary):
	for p in state.keys():
		set(p, state[p])
	$Component_NetworkedRigidBody.puppet_transform = global_transform
	$PlayerShape.disabled = not is_network_master()
