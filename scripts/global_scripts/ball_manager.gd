extends Node2D
class_name BallManager


### GLOBAL BALL SETTINGS
var gravity: float = 900
var bounciness: float = 0.95
var max_bounces_per_frame: int = 3
var slipperiness: float = 1.5
var ball_radius: int = 16


@export var ball_multimesh: MultiMeshInstance2D

### DATA STRUCTURE
class BallData extends RefCounted:
	var active: bool = true
	var pos: Vector2 = Vector2.ZERO
	var last_frame_pos: Vector2 = Vector2.ZERO
	var vel: Vector2 = Vector2.ZERO
	var air_time: float = 0.0
	var inactive_time: float = 0.0
	var is_sliding: bool = false
	var visual_instance_id: int = -1 

var active_balls: Array[BallData] = []

var ray_offsets: Array[Vector2] = [
	Vector2(-ball_radius, 0), # Left
	Vector2(0, 0),  # Center
	Vector2(ball_radius, 0)   # Right
]

func _ready():
	
	SignalBus.spawn_ball.connect(spawn_ball)


func spawn_ball(spawn_pos: Vector2,spawn_vel: Vector2 = Vector2.ZERO):
	var new_ball = BallData.new()
	new_ball.pos = spawn_pos
	new_ball.last_frame_pos = spawn_pos
	new_ball.vel = spawn_vel
	
	if ball_multimesh and ball_multimesh.multimesh:
		new_ball.visual_instance_id = active_balls.size()
	
	
	active_balls.append(new_ball)


func _physics_process(delta):
	var space_state = get_world_2d().direct_space_state
	
	for ball in active_balls:
		if not ball.active:
			continue
			
		process_single_ball(ball, delta, space_state)
		update_ball_visuals(ball)

func process_single_ball(ball: BallData, delta: float, space_state: PhysicsDirectSpaceState2D):
	var has_bounced_this_frame = false
	
	# 1. Apply Gravity
	ball.vel.y += gravity * delta
	var move_vec: Vector2 = ball.vel * delta
	
	# 2. Check Air Time
	var in_air = check_if_in_air(ball, space_state)
	if in_air:
		ball.air_time += delta
		if ball.air_time > 0.33:
			ball.is_sliding = false
	else:
		ball.air_time = 0
		
	# 3. Collision & Bouncing Loop
	for i in max_bounces_per_frame:
		var coll_result = run_coll_check(ball, move_vec, space_state)
		
		if coll_result.has("is_valid") and coll_result.is_valid:
			has_bounced_this_frame = true
			perform_collision(ball, coll_result)
			# Recalculate move_vec for remaining bounces
			move_vec = ball.vel * delta 
		else:
			break
			
	# 4. Move Ball if no bounce interrupted it
	if not has_bounced_this_frame:
		ball.pos += move_vec
		
	# 5. Inactivity Check (Sleep)
	if ball.pos.distance_to(ball.last_frame_pos) <= 1:
		ball.inactive_time += delta
		if ball.inactive_time > 10:
			ball.active = false # Disable ball
	else:
		ball.inactive_time = 0
		
	ball.last_frame_pos = ball.pos

func run_coll_check(ball: BallData, move_vec: Vector2, space_state: PhysicsDirectSpaceState2D) -> Dictionary:
	var hit_normals: Array[Vector2] = []
	var hit_points: Array[Vector2] = []
	var hit_pegs: Array[Node2D] = []
	
	var ray_rot = move_vec.angle() - (PI/2)
	
	var query = PhysicsRayQueryParameters2D.new()
	query.collide_with_areas = true
	
	for offset in ray_offsets:
		# Rotate offset to match movement direction
		var rotated_offset = offset.rotated(ray_rot)
		var start_pos = ball.pos + rotated_offset
		var end_pos = start_pos + move_vec
		
		query.from = start_pos
		query.to = end_pos
		
		var result = space_state.intersect_ray(query)
		
		if result:
			hit_normals.append(result.normal)
			hit_points.append(result.position)
			
			var collider = result.collider
			if collider is DestructiblePeg and not hit_pegs.has(collider):
				hit_pegs.append(collider)
				
	if hit_normals.is_empty():
		return {"is_valid": false}
		
	# Calculate Averages
	var avg_normal = Vector2.ZERO
	for n in hit_normals: avg_normal += n
	avg_normal = (avg_normal / hit_normals.size()).normalized()
	
	var closest_hit_point = hit_points[0] # Simplified for performance: just grab the first or average
	
	# Bouncing Math
	var bounce_vec = move_vec.bounce(avg_normal).normalized()
	var dif_to_vel = bounce_vec.distance_to(ball.vel.normalized())
	
	if dif_to_vel < slipperiness:
		if dif_to_vel < 0.01:
			return {"is_valid": false}
			
		ball.is_sliding = true
		var slide_velocity = ball.vel - avg_normal * ball.vel.dot(avg_normal)
		slide_velocity += avg_normal * (50000.0 / max(ball.vel.length(), 1.0))
		
		queue_pegs_for_destruction(hit_pegs)
		return {
			"is_valid": true,
			"bounce_vector": slide_velocity.normalized(),
			"collision_point": closest_hit_point
		}
		
	queue_pegs_for_destruction(hit_pegs)
	return {
		"is_valid": true,
		"bounce_vector": bounce_vec,
		"collision_point": closest_hit_point
	}

func perform_collision(ball: BallData, data: Dictionary):
	var speed = ball.vel.length()
	ball.vel = data.bounce_vector * speed
	
	var coll_pos = data.collision_point - ball.pos.direction_to(data.collision_point) * ball_radius
	ball.pos = coll_pos
	
	if not ball.is_sliding:
		ball.vel *= bounciness

func check_if_in_air(ball: BallData, space_state: PhysicsDirectSpaceState2D) -> bool:
	# Cast a short ray downwards to check for floor
	var query = PhysicsRayQueryParameters2D.new()
	query.from = ball.pos
	query.to = ball.pos + Vector2(0, 20)
	query.collide_with_areas = true
	return space_state.intersect_ray(query).is_empty()

func queue_pegs_for_destruction(pegs: Array[Node2D]):
	for peg in pegs:
		if peg.has_method("queue_destruction"):
			peg.queue_destruction() 

func update_ball_visuals(ball: BallData):
	if ball_multimesh and ball.visual_instance_id >= 0:
		var trans = Transform2D(0, ball.pos)
		ball_multimesh.multimesh.set_instance_transform_2d(ball.visual_instance_id, trans)

		if ball.is_sliding:
			ball_multimesh.multimesh.set_instance_color(ball.visual_instance_id, Color.RED)
		else:
			ball_multimesh.multimesh.set_instance_color(ball.visual_instance_id, Color.WHITE)
