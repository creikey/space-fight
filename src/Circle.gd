tool
extends Node2D

export var color := Color(1, 1, 1)
export var radius: float = 16.0

func _process(_delta):
	set_process(Engine.editor_hint)
	update()

func _draw():
	draw_circle(Vector2(), radius, color)
