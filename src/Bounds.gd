extends StaticBody2D

export var length: float = 3000.0

func _ready():
	$TopWall.shape.b.x = length
	$BottomWall.position.y = length
	$RightWall.position.x = length
	
	$ColorRect.rect_size = Vector2(length, length)
	$InBoundsPattern.region_rect.size = $ColorRect.rect_size
