extends Node2D
class_name BallManager


### GLOBAL BALL SETTINGS
var gravity: float = 900
var bounciness: float = 0.95
var max_bounces_per_frame: int = 3
var slipperiness: float = 1.2
var spin_sensitivity: float = 1.0/140.0

var max_number_of_balls: int = 1000
var max_number_of_sim_balls: int = 10000
var max_allowed_ball_radius: float = 64

var simulate_time: float = 0.6

### EXPORT VARS
@export var adjustable_ball_multimesh: MultiMeshInstance2D

@export var adjustable_shadow_multimesh: MultiMeshInstance2D

@export var simulated_ball_multimesh: MultiMeshInstance2D

### DATA STRUCTURE
class BallData extends RefCounted:
	var active: bool = true
	var simulated: bool = false
	var frames_simulated: int = 0
	var pos: Vector2 = Vector2.ZERO
	var last_frame_pos: Vector2 = Vector2.ZERO
	var vel: Vector2 = Vector2.ZERO
	var air_time: float = 0.0
	var inactive_time: float = 0.0
	var is_sliding: bool = false
	var visual_instance_id: int = -1 
	var roll_offset: Vector2 = Vector2.ZERO
	var radius: float = 16
	var vis_scale: float = 1.0
	var ray_offsets: Array[Vector2] = []

###
var active_balls: Array[BallData] = []

var curr_simulated_ball: BallData
var simulated_positions: Array[Vector2]
###

var delta_timer: float = 0
var mouse_has_moved_this_frame: bool = false
var last_frame_mouse_pos: Vector2 = Vector2.ZERO
var sim_ball_point_distribution: int = 2


func _ready():
	
	SignalBus.spawn_ball.connect(spawn_ball)
	SignalBus.spawn_simulated_ball.connect(spawn_simulated_ball)
	
	adjustable_ball_multimesh.multimesh.instance_count = max_number_of_balls
	for i in range(max_number_of_balls):
		adjustable_ball_multimesh.multimesh.set_instance_transform_2d(i, Transform2D(0, Vector2.ZERO, 0, Vector2.ZERO))
	
	adjustable_shadow_multimesh.multimesh.instance_count = max_number_of_balls
	for i in range(max_number_of_balls):
		adjustable_shadow_multimesh.multimesh.set_instance_transform_2d(i, Transform2D(0, Vector2.ZERO, 0, Vector2.ZERO))
	
	simulated_ball_multimesh.multimesh.instance_count = max_number_of_sim_balls
	for i in range(max_number_of_sim_balls):
		simulated_ball_multimesh.multimesh.set_instance_transform_2d(i, Transform2D(0, Vector2.ZERO, 0, Vector2.ZERO))


func spawn_ball(spawn_pos: Vector2, spawn_vel: Vector2 = Vector2.ZERO, spawn_radius: float = 16.0):
	
	for ball in active_balls:
		if not ball.active:
			# Revive ball if therers one available
			ball.active = true
			ball.pos = spawn_pos
			ball.last_frame_pos = spawn_pos
			ball.vel = spawn_vel
			ball.air_time = 0.0
			ball.inactive_time = 0.0
			ball.is_sliding = false
			ball.roll_offset = Vector2.ZERO
			return
	
	# If no dead balls make new one
	var new_ball = BallData.new()
	
	new_ball.radius = clamp(spawn_radius,1,max_allowed_ball_radius)
	new_ball.pos = spawn_pos
	new_ball.last_frame_pos = spawn_pos
	new_ball.vel = spawn_vel
	new_ball.visual_instance_id = active_balls.size()
	
	active_balls.append(new_ball)

func spawn_simulated_ball(spawn_pos: Vector2, spawn_vel: Vector2 = Vector2.ZERO, spawn_radius: float = 16.0):
	
	
	var new_ball = BallData.new()
	
	new_ball.simulated = true
	new_ball.radius = clamp(spawn_radius,1,max_allowed_ball_radius)
	new_ball.pos = spawn_pos
	new_ball.last_frame_pos = spawn_pos
	new_ball.vel = spawn_vel
	new_ball.visual_instance_id = 1
	
	curr_simulated_ball = new_ball


func _physics_process(delta):
	
	var mpos: Vector2 = get_global_mouse_position()
	if last_frame_mouse_pos != mpos:
		mouse_has_moved_this_frame = true
	else:
		mouse_has_moved_this_frame = false
	
	last_frame_mouse_pos = mpos
	
	
	var space_state = get_world_2d().direct_space_state
	
	for ball in active_balls:
		if not ball.active:
			continue
			
		process_single_ball(ball, delta, space_state)
		update_ball_visuals(ball)
	
	
	if mouse_has_moved_this_frame:
		
		for i in simulate_time*144:
			process_single_ball(curr_simulated_ball, delta, space_state)
		
		update_sim_ball_visuals()
		simulated_positions = []


func process_single_ball(ball: BallData, delta: float, space_state: PhysicsDirectSpaceState2D):
	
	var has_bounced_this_frame = false
	
	var move_vec: Vector2 = ball.vel * delta
	
	ball.frames_simulated += 1
	
	# Check Air Time
	var in_air = check_if_in_air(ball, space_state)
	if in_air:
		ball.air_time += delta
		if ball.air_time > 0.33:
			ball.is_sliding = false
	else:
		ball.air_time = 0
		
	# Collision & Bouncing Loop
	for i in max_bounces_per_frame:
		var coll_result = run_coll_check(ball, move_vec, space_state)
		
		if coll_result.has("is_valid") and coll_result.is_valid:
			has_bounced_this_frame = true
			perform_collision(ball, coll_result)
			# Recalculate move_vec for remaining bounces
			move_vec = ball.vel * delta
			
			if not ball.simulated:
				bounce_anim(ball)
		else:
			break
	
	
	# Move Ball if no bounce interrupted it
	if not has_bounced_this_frame:
		var no_bounce_pos: Vector2 = ball.pos + move_vec
		ball.pos = no_bounce_pos
		if ball.simulated and curr_simulated_ball.frames_simulated % sim_ball_point_distribution == 0:
			simulated_positions.append(no_bounce_pos)
		
	
	# Inactivity Check
	if ball.pos.distance_to(ball.last_frame_pos) <= 1:
		ball.inactive_time += delta
		if ball.inactive_time > 10:
			ball.active = false # Disable ball
	else:
		ball.inactive_time = 0
	
	ball.last_frame_pos = ball.pos
	
		
	# Apply Gravity
	ball.vel.y += gravity * delta
	
	# DEBUG
	#delta_timer += delta
	#ball.vis_scale = (sin(delta_timer)+2)
	
	ball.roll_offset += ball.vel * delta * spin_sensitivity
	
	ball.roll_offset.x = fmod(ball.roll_offset.x, 1.0)
	ball.roll_offset.y = fmod(ball.roll_offset.y, 1.0)
	

func run_coll_check(ball: BallData, move_vec: Vector2, space_state: PhysicsDirectSpaceState2D) -> Dictionary:
	var hit_pegs: Array[Node2D] = []
	
	# Track the absolute closest hit from our parallel sweeps
	var closest_hit_dist: float = INF
	var closest_hit_point: Vector2 = Vector2.ZERO
	var hit_something: bool = false
	var has_hit_peg: bool = false
	
	var closest_collider: Node2D
	
	var ray_rot = move_vec.angle() - (PI/2)
	
	var query = PhysicsRayQueryParameters2D.new()
	query.collide_with_areas = true
	
	# more rays for bigger balls, so pegs cant go inbetween rays
	# its still really buggy for anything bigger than 32 though
	if ball.radius >= 20 and ball.radius <= 40: #big ball
		ball.ray_offsets = [
			Vector2(-ball.radius, 0), # Left
			Vector2(-ball.radius/2.0, 0), # Left
			Vector2(0, ball.radius),  # Center
			Vector2(ball.radius/2.0, 0),   # Right
			Vector2(ball.radius, 0)   # Right
		]
	elif ball.radius > 40: #huuuge ball
		ball.ray_offsets = [
			Vector2(-ball.radius, 0), # Left
			Vector2(-ball.radius*(1.0/3.0), 0), # Left
			Vector2(-ball.radius*(2.0/3.0), 0), # Left
			Vector2(0, ball.radius),  # Center
			Vector2(ball.radius*(1.0/3.0), 0),   # Right
			Vector2(ball.radius*(2.0/3.0), 0),   # Right
			Vector2(ball.radius, 0)   # Right
		]
	else: #normal ball
		ball.ray_offsets = [
			Vector2(-ball.radius, 0), # Left
			Vector2(0, ball.radius),  # Center
			Vector2(ball.radius, 0)   # Right
		]
	
	for offset in ball.ray_offsets:
		# Rotate offset to match movement direction
		var rotated_offset = offset.rotated(ray_rot)
		var start_pos = ball.pos + rotated_offset
		var end_pos = start_pos + move_vec
		
		query.from = start_pos
		query.to = end_pos
		
		var result = space_state.intersect_ray(query)
		
		if result:
			hit_something = true
			
			var dist = ball.pos.distance_squared_to(result.position)
			if dist < closest_hit_dist:
				closest_hit_dist = dist
				closest_hit_point = result.position
			
			var collider: Area2D = result.collider
			closest_collider = collider
			if collider is DestructiblePeg and not hit_pegs.has(collider):
				hit_pegs.append(collider)
				has_hit_peg = true
			
			if collider.is_in_group("ball_kill"):
				ball.active = false
			
	if not hit_something:
		return {"is_valid": false}
	
	
	# different logic here because the first approach only works for small colliders with simple shapes (pegs)
	if has_hit_peg:
		# Cast  ray from the ball center to the found collider
		query.from = ball.pos
		query.to = closest_collider.global_position
	else:
		var dir_to_hit = ball.pos.direction_to(closest_hit_point)
		query.from = ball.pos
		query.to = closest_hit_point + (dir_to_hit * 2.0)
	
	var final_result = space_state.intersect_ray(query)
	var target_normal = Vector2.ZERO
	
	if final_result:
		target_normal = final_result.normal
		closest_hit_point = final_result.position
	else:
		# Fallback normal
		target_normal = -move_vec.normalized()
	
	var bounce_vec = move_vec.bounce(target_normal).normalized()
	var dif_to_vel = bounce_vec.distance_to(ball.vel.normalized())
	
	if dif_to_vel < slipperiness:
		if dif_to_vel < 0.01:
			return {"is_valid": false}
			
		ball.is_sliding = true
		var slide_velocity = ball.vel - target_normal * ball.vel.dot(target_normal)
		slide_velocity += target_normal * (50000.0 / max(ball.vel.length(), 1.0))
		
		if not ball.simulated:
			queue_pegs_for_destruction(hit_pegs)
		
		return {
			"is_valid": true,
			"bounce_vector": slide_velocity.normalized(),
			"collision_point": closest_hit_point
		}
	
	if not ball.simulated:
		queue_pegs_for_destruction(hit_pegs)
	
	return {
		"is_valid": true,
		"bounce_vector": bounce_vec,
		"collision_point": closest_hit_point
	}

func perform_collision(ball: BallData, data: Dictionary):
	var speed = ball.vel.length()
	ball.vel = data.bounce_vector * speed
	
	var coll_pos = data.collision_point - ball.pos.direction_to(data.collision_point) * ball.radius
	
	ball.pos = coll_pos
	
	if ball.simulated and curr_simulated_ball.frames_simulated % sim_ball_point_distribution == 0:
		simulated_positions.append(coll_pos)
	
	
	
	
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
	
	if adjustable_ball_multimesh and adjustable_shadow_multimesh and ball.visual_instance_id >= 0:
		var multmesh_i: int = ball.visual_instance_id
		
		# if ball is dead hide it, by setting its scale to 0
		if not ball.active:
			adjustable_ball_multimesh.multimesh.set_instance_transform_2d(multmesh_i, Transform2D(0, Vector2.ZERO, 0, Vector2.ZERO))
			return 
		
		# draw active ball
		var trans = Transform2D(0,ball.vis_scale*Vector2.ONE,0, ball.pos)
		adjustable_ball_multimesh.multimesh.set_instance_transform_2d(multmesh_i, trans)
		
		var custom_data = Color(ball.roll_offset.y, ball.roll_offset.x, ball.radius, 0.0)
		adjustable_ball_multimesh.multimesh.set_instance_custom_data(multmesh_i, custom_data)
		
		# draw follow shadow
		var s_vel: Vector2 = ball.vel * get_physics_process_delta_time() * 0.04
		
		var s_data = Color(-s_vel.x,s_vel.y,ball.radius)
		adjustable_shadow_multimesh.multimesh.set_instance_custom_data(multmesh_i, s_data)
		
		var s_trans = Transform2D(0, ball.pos - ball.vel * get_physics_process_delta_time())
		adjustable_shadow_multimesh.multimesh.set_instance_transform_2d(multmesh_i, s_trans)
		
		
		### BUG: change shader to use COLOR so this works
		if ball.is_sliding:
			adjustable_ball_multimesh.multimesh.set_instance_color(multmesh_i, Color.RED)
		else:
			adjustable_ball_multimesh.multimesh.set_instance_color(multmesh_i, Color.WHITE)
		


func clear_sim_ball_visuals():
	if not simulated_positions: return
	
	for i in simulated_positions.size() + 1:
		simulated_ball_multimesh.multimesh.set_instance_transform_2d(i, Transform2D(0, Vector2.ZERO, 0, Vector2.ZERO))

func update_sim_ball_visuals():
	clear_sim_ball_visuals()
	if simulated_ball_multimesh and simulated_positions:
		for i in simulated_positions.size():
			
			# draw active ball
			var trans = Transform2D(0,Vector2.ONE,0, simulated_positions[i])
			simulated_ball_multimesh.multimesh.set_instance_transform_2d(i, trans)
			
		




func bounce_anim(anim_ball: BallData):
	var tween = create_tween()
	tween.tween_property(anim_ball,"vis_scale",0.8,0.06).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(anim_ball,"vis_scale",1.4,0.02).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(anim_ball,"vis_scale",1.0,0.05)
