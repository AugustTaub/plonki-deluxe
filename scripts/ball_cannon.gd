extends Node2D


var start_speed: float = 600
 
@onready var ball_spawn_point: Node2D = $pivot/ball_spawn_point

var delta_timer: float = 0
var shot_interval: float = 0.5

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	delta_timer += delta
	
	$pivot.look_at(get_global_mouse_position())
	$pivot.rotate(-PI/2)
	
	var pos = ball_spawn_point.global_position
	var vel = global_position.direction_to(ball_spawn_point.global_position) * start_speed
	var radius = 16.0
	
	if sin(delta_timer*(1/delta))>0:
		SignalBus.spawn_simulated_ball.emit(pos,vel,radius)
	
	
	if Input.is_action_just_pressed("fire_ball"):
		#if delta_timer >= shot_interval:
		delta_timer = 0
		SignalBus.spawn_ball.emit(pos,vel,radius)
