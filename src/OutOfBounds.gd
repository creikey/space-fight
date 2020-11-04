extends Sprite

#func _ready():
#	position = -region_rect/2.0

func _process(delta):
	region_rect.position += Vector2(2.4, 1.3)*delta*20.0
