extends RigidBody2D

const MOTION_SPEED = 500.0
const THRUST: float = 500.0

onready var _collision_normal_finder: RayCast2D = $CollisionNormalFinder
onready var _collision_shape: CollisionShape2D = $PlayerShape

sync var health: float = 1.0
var dead: bool = true # dead by default
var respawn_time: float = -1.0
var controlling_peer: int = -1 # peer that will manage my input
var spawn_transform: Transform2D =Transform2D(0.0, Vector2())

var _movement := Vector2() # only set and used on the network master

# depends on the gamestate singleton dead body counter variable
func get_dead_body_state() -> Dictionary:
	var properties_to_return: Array = ["global_transform", "linear_velocity", "angular_velocity"]
	var to_return: Dictionary = {}
	for p in properties_to_return:
		to_return[p] = get(p)
	to_return["name"] = str(get_tree().get_network_unique_id(), "_deadbody_", gamestate.dead_body_counter)
	return to_return
	
puppetsync func die(dead_body_state: Dictionary):
	var new_body: DeadBody = preload("res://DeadBody.tscn").instance()
	new_body.name = dead_body_state["name"] # hack, shouldn't rely on name in dict
	get_parent().call_deferred("add_child", new_body)
	new_body.call_deferred("create_from_state", dead_body_state)
	dead = true
	visible = false
	_collision_shape.set_deferred("disabled", true)
	set_deferred("mode", RigidBody2D.MODE_STATIC)
	respawn_time = 3.0

puppetsync func respawn():
	dead = false
	visible = true
	_collision_shape.set_deferred("disabled", not is_network_master())
	set_deferred("mode", RigidBody2D.MODE_RIGID)
	respawn_time = -1.0
	health = 1.0
	set_deferred("global_transform", spawn_transform)

func _is_managing_client() -> bool: # this node will manage input!
	return controlling_peer == get_tree().get_network_unique_id()

func _physics_process(delta: float):
	$MyHealthBar.value = health
	
	if respawn_time > 0.0:
		respawn_time -= delta
	
	if _is_managing_client(): 
		UILayer.ui.health = health
		UILayer.ui.respawn_time = respawn_time
		var movement_to_transmit: Vector2 = Vector2(\
			float(Input.is_action_pressed("g_right")) - float(Input.is_action_pressed("g_left")),
			float(Input.is_action_pressed("g_down")) - float(Input.is_action_pressed("g_up"))
		)
		if dead:
			movement_to_transmit = Vector2()
#		printt("Transmitting movement ", movement_to_transmit)
#		rpc_unreliable("receive_movement", movement_to_transmit)
		rpc_unreliable_id(get_network_master(), "receive_movement", movement_to_transmit)

	if is_network_master():
		if dead:
			if respawn_time < 0.0:
				rpc("respawn")
		else:
			applied_force = _movement * THRUST
		_collision_normal_finder.cast_to = _collision_normal_finder.to_local(global_position + linear_velocity.normalized() * 50.0)
		health += 0.05*delta
		rset("health", health)
		if health <= 0.0 and not dead:
			rpc("die", get_dead_body_state())
			gamestate.dead_body_counter += 1

master func receive_movement(new_movement: Vector2):
	if get_tree().get_rpc_sender_id() != controlling_peer:
		printerr("Warning: Somebody trying to send movement that isn't the controlling peer. Fishy!")
		return
#	printt("Setting to movement: ", new_movement)
	_movement = new_movement

func set_player_name(new_name):
	get_node("label").set_text(new_name)

func _integrate_forces(state: Physics2DDirectBodyState):
	if not is_network_master() or dead:
		return
	for c in state.get_contact_count():
		var impact_velocity: float = linear_velocity.project(state.get_contact_local_normal(c)).length()
		print(impact_velocity)
		if impact_velocity > 5.0:
			health -= min(0.5, impact_velocity/600.0)
			rset("health", health)

#	if _collision_normal_finder.is_colliding():
#		print(linear_velocity.normalized().dot(_collision_normal_finder.get_collision_normal().normalized()))

func _ready():
	respawn()
