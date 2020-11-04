extends Node2D

const spacing: float = 50.0

#export var spacing: float = 50.0

func _ready():
	for i in get_child_count():
		get_child(i).position = Vector2(0, i*spacing)
