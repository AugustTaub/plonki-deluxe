extends Node2D

var delta_timer: float = 0

var ball_scn: PackedScene = preload("res://scenes/ball.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	delta_timer += delta
	
	#if delta_timer >= 1:
		#delta_timer = 0
		#var instance = ball_scn.instantiate()
		#add_child(instance)
