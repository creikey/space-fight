extends RigidBody2D

var spawn_point := Vector2()

func _ready():
	spawn_point = global_position

func scored():
	set_deferred("global_position", spawn_point)
	linear_velocity = Vector2()
	angular_velocity = 0.0
