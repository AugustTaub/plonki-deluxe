extends BallInteractibleObject

class_name BallInteractibleFallingBlock

@export var sprite: Sprite2D
@export var falling_area: Area2D

var is_falling:


func perform_interaction(ball_data: BallManager.BallData) -> BallManager.BallData:
	
	
	
	
	return ball_data


func reset():
	falling_area.global_position = global_position
