extends Node

var far_away_pos: Vector2 = Vector2(50000,50000)

var nr_of_instances: int = 500

var preloaded_ball: PackedScene = preload("res://scenes/ball.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in nr_of_instances:
		var b_instance: Ball = preloaded_ball.instantiate()
		add_child(b_instance)
		b_instance.global_position = far_away_pos
		b_instance.disabled = true

func get_ball():
	if get_child_count() == 0:
		print("NO MORE BALLS")
		return
	
	var first_child: Ball = get_child(0)
	first_child.set_disabled(false)
	first_child.reparent(get_tree().root)
	first_child.global_position = Vector2.ZERO
	return first_child

func return_ball(returned_ball: Ball):
	returned_ball.reparent(self)
	returned_ball.set_disabled(true)
	returned_ball.global_position = far_away_pos
