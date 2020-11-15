extends Control

class_name UI

var health: float = 1.0
var respawn_time: float = -1.0

func _process(_delta):
	visible = gamestate.in_game()
	$HealthBar.value = health
	$RespawnCountdown.visible = respawn_time >= 0.0
	$RespawnCountdown.text = str(stepify(respawn_time, 0.1))
