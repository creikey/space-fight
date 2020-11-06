extends Label

func _process(_delta):
	text = str("Frame: ", gamestate.frame)
