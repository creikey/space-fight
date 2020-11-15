extends Area2D

export var to_add_score: String 
export var balls_target_group: String

func _on_TeamGoal_body_entered(body):
	if not is_network_master():
		return
	if body.is_in_group(balls_target_group):
		gamestate.rpc("modify_team_score", to_add_score, 1)
		body.scored()
