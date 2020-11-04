extends Camera2D

var target: Node2D = null

func _process(_delta):
	if target != null:
		global_position = target.global_position
