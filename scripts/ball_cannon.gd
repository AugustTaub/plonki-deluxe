extends Node2D


var start_speed: float = 500
 
@onready var ball_spawn_point: Node2D = $pivot/ball_spawn_point

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	$pivot.look_at(get_global_mouse_position())
	$pivot.rotate(-PI/2)
	
	if Input.is_action_just_pressed("fire_ball"):
		var pos = ball_spawn_point.global_position
		var vel = global_position.direction_to(ball_spawn_point.global_position) * start_speed
		SignalBus.spawn_ball.emit(pos,vel)
