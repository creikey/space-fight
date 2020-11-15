extends RigidBody2D

const MOTION_SPEED = 500.0
const THRUST: float = 300.0

onready var _collision_normal_finder: RayCast2D = $CollisionNormalFinder
onready var _collision_shape: CollisionShape2D = $PlayerShape

sync var health: float = 1.0
var dead: bool = true # dead by default
var respawn_time: float = -1.0
var controlling_peer: int = -1 # peer that will manage my input
var spawn_transform: Transform2D =Transform2D(0.0, Vector2())

var _movement := Vector2() # only set and used on the network master

func get_dead_body_state() -> Dictionary:
	var properties_to_return: Array = ["linear_velocity", "angular_velocity", "global_transform"]
	var to_return: Dictionary = {}
	for p in properties_to_return:
		to_return[p] = get(p)
	return to_return
	
puppetsync func die(dead_body_state: Dictionary):
	var new_body: DeadBody = preload("res://DeadBody.tscn").instance()
	get_parent().add_child(new_body)
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

		if health <= 0.0 and not dead:
			rpc("die", get_dead_body_state())

master func receive_movement(new_movement: Vector2):
	if get_tree().get_rpc_sender_id() != controlling_peer:
		printerr("Warning: Somebody trying to send movement that isn't the controlling peer. Fishy!")
		return
#	printt("Setting to movement: ", new_movement)
	_movement = new_movement

func set_player_name(new_name):
	get_node("label").set_text(new_name)


func _on_player_body_entered(_body):
#	printt(linear_velocity.length(), linear_velocity.length()/300.0)
	if is_network_master() and not dead and linear_velocity.length() > 100.0:
		health -= min(0.5, linear_velocity.length()/1500.0)
		rset("health", health)
#	if _collision_normal_finder.is_colliding():
#		print(linear_velocity.normalized().dot(_collision_normal_finder.get_collision_normal().normalized()))

func _ready():
	respawn()
