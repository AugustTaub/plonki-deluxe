extends Node2D

### GLOBAL BALL SETTINGS
@export var roll_sensitivity: float = 0.2
@export var rot_sensitivity: float = -1

@export var max_number_of_balls: int = 200
@export var spawn_vel: float = 20.0 
@export var ball_gravity: float = 400.0

@export var ball_max_bounce: float = 100

### EXPORT VARS
@export var adjustable_ball_multimesh: MultiMeshInstance2D

### DATA STRUCTURE
class BallData extends RefCounted:
	var active: bool = false
	var instance_id: int = -1 
	
	var tube_pos: float = 0.0 
	
	var pos: Vector2 = Vector2.ZERO 
	
	var bounces_made: int = 0
	var radius: float = 16
	var vel: float = 0
	var roll_offset: Vector2 = Vector2.ZERO
	var rotation_offset: float = 0

### POOLS
var active_queue: Array[BallData] = []
var inactive_pool: Array[BallData] = []

####

@onready var spawn_point: Vector2 = $ball_spawn_point.global_position
@onready var despawn_point: Vector2 = $ball_despawn_point.global_position

@onready var ball_travel_vec: Vector2 = despawn_point - spawn_point
@onready var travel_dir: Vector2 = ball_travel_vec.normalized()
@onready var tube_length: float = ball_travel_vec.length()

@onready var height_dir: Vector2 = travel_dir.orthogonal().normalized() 

###
var delta_timer: float = 0

func _ready():
	
	adjustable_ball_multimesh.multimesh.instance_count = max_number_of_balls
	
	# Initialize the object pool and hide all multimeshes
	for i in range(max_number_of_balls):
		var new_ball = BallData.new()
		new_ball.instance_id = i
		inactive_pool.append(new_ball)
		adjustable_ball_multimesh.multimesh.set_instance_transform_2d(i, Transform2D(0, Vector2.ZERO, 0, Vector2.ZERO))
		
	spawn_ball()

func spawn_ball(spawn_radius: float = 16.0):
	if inactive_pool.is_empty():
		return 
		
	var ball = inactive_pool.pop_back()
	ball.active = true
	
	ball.radius = spawn_radius
	ball.tube_pos = 0.0
	ball.vel = spawn_vel
	
	ball.roll_offset = Vector2.ZERO
	ball.rotation_offset = 0
	ball.bounces_made = 0
	
	active_queue.push_back(ball)

func take_ball_from_end():
	if active_queue.is_empty():
		return
	
	var ball = active_queue.pop_front()
	ball.active = false
	inactive_pool.push_back(ball)
	
	adjustable_ball_multimesh.multimesh.set_instance_transform_2d(ball.instance_id, Transform2D(0, Vector2.ZERO, 0, Vector2.ZERO))
	
	animate_ball_exit(ball.pos, ball.roll_offset, ball.rotation_offset, ball.radius)


func _physics_process(delta):
	if Input.is_action_just_pressed("fire_ball"):
		take_ball_from_end()
	
	delta_timer += delta
	if delta_timer > 1:
		spawn_ball(randf_range(8,32))
		delta_timer = 0
	
	
	for i in range(active_queue.size()):
		var ball: BallData = active_queue[i]
		
		# gravity
		ball.vel += ball_gravity * delta
		
		# apply vel
		var movement = ball.vel * delta
		ball.tube_pos += movement
		
		# stop when end reached
		if ball.tube_pos >= tube_length:
			ball.tube_pos = tube_length
			ball.vel = 0
		
		# ball collision
		if i > 0:
			var ball_ahead: BallData = active_queue[i - 1]
			
			var required_spacing = 2.0 * sqrt(ball.radius * ball_ahead.radius)
			
			if ball.tube_pos > ball_ahead.tube_pos - required_spacing:
				ball.tube_pos = ball_ahead.tube_pos - required_spacing
				
				if ball.bounces_made == 0:
					ball.vel = -ball_max_bounce
					ball.bounces_made += 1
				elif ball.bounces_made <= 2:
					ball.vel = -ball_max_bounce/2
					ball.bounces_made += 1
				else:
					ball.vel = ball_ahead.vel * 0.1
			
			
		ball.pos = spawn_point + (travel_dir * ball.tube_pos) + (height_dir * ball.radius)
		
		# --- VISUAL UPDATES ---
		
		ball.rotation_offset += ball.vel * rot_sensitivity * delta
		ball.rotation_offset = fmod(ball.rotation_offset, 360.0)
		
		ball.roll_offset += travel_dir * movement * roll_sensitivity * delta
		ball.roll_offset.x = fmod(ball.roll_offset.x, 1.0)
		ball.roll_offset.y = fmod(ball.roll_offset.y, 1.0)
		
		update_ball_visuals(ball)

func update_ball_visuals(ball: BallData):
	if not adjustable_ball_multimesh: 
		return
	
	var trans = Transform2D(0, Vector2.ONE, 0, ball.pos)
	adjustable_ball_multimesh.multimesh.set_instance_transform_2d(ball.instance_id, trans)
	
	var custom_data = Color(-ball.roll_offset.x, ball.roll_offset.y, ball.radius, deg_to_rad(ball.rotation_offset))
	adjustable_ball_multimesh.multimesh.set_instance_custom_data(ball.instance_id, custom_data)

func animate_ball_exit(ball_pos: Vector2, ball_roll_offset: Vector2, ball_rot_offset: float, ball_radius):
	
	for child in $bands.get_children():
		if child is AnimatedSprite2D:
			child.speed_scale = 5.5
	
	var i: int = 0
	
	var start_trans = Transform2D(0, Vector2.ONE, 0, ball_pos)
	var end_trans = Transform2D(2*PI, Vector2.ONE, 0, despawn_point + (height_dir * ball_radius))
	
	adjustable_ball_multimesh.multimesh.set_instance_transform_2d(i, start_trans)
	
	var custom_data = Color(-ball_roll_offset.x, ball_roll_offset.y, ball_radius, deg_to_rad(ball_rot_offset))
	adjustable_ball_multimesh.multimesh.set_instance_custom_data(i, custom_data)

	var tween = create_tween()
	
	var dur = ball_pos.distance_to(despawn_point)/2000.0
	
	tween.tween_method(
		func(current_trans: Transform2D): 
			adjustable_ball_multimesh.multimesh.set_instance_transform_2d(i, current_trans),
		start_trans, 
		end_trans, 
		dur
	).set_ease(Tween.EASE_IN)
	
	await  tween.finished
	adjustable_ball_multimesh.multimesh.set_instance_transform_2d(i, Transform2D(0, Vector2.ZERO, 0, Vector2.ZERO))
	
	for child in $bands.get_children():
		if child is AnimatedSprite2D:
			child.speed_scale = 1.0
