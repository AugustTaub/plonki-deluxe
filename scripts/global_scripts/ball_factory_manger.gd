extends Node

var queued_balls: Array[float] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func add_ball_to_queue(radius: float):
	pass

func remove_last_ball_from_queue():
	queued_balls.pop_back()
