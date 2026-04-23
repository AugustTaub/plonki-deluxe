extends BallInteractibleObject

class_name BallTeleporter

@export var paired_telporter: BallTeleporter

func perform_interaction(ball_data: BallManager.BallData) -> BallManager.BallData:
	
	if paired_telporter:
		ball_data.pos = paired_telporter.global_position
	return ball_data
