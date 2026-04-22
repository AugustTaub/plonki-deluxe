extends BallInteractibleObject


func perform_interaction(ball_data: BallManager.BallData) -> BallManager.BallData:
	ball_data.active = false
	return ball_data
