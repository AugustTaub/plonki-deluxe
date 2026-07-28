extends Node2D

class_name Ball

var gravity: float = 900 # gravity in px per sec

var bounciness: float = 0.95 # how much velocity is retained with each bounce 0-1

var max_bounces_per_frame: int = 3
var has_bounced_this_frame: bool = false

var slipperiness: float = 1.5 # how similar the slop has to be to the velocity initiate a slide 0-2 (0 is no slide)
var is_sliding: bool = false

var air_time: float = 0

var velocity: Vector2 = Vector2.ZERO


var coll_ray_arr: Array[RayCast2D]
var start_y_target_dict: Dictionary[RayCast2D, float]

var last_frame_pos: Vector2 = Vector2.ZERO

var inactive_time: float = 0

var disabled: bool = false

@onready var coll_rays_node: Node2D = $coll_rays
@onready var ball_sprite_node: Node2D = $ball_sprite

# overwritten every frame
var _hit_normal_dict: Dictionary = {}
var _hit_point_dict: Dictionary = {}
var _hit_pegs: Array[DestructiblePeg] = []

var _coll_data: CollData = CollData.new()

var _look_at_vector: Vector2 = Vector2.ZERO


class CollData extends RefCounted:
	var is_valid: bool
	var collision_point: Vector2
	var bounce_vector: Vector2
	
	func _init(p_is_valid: bool = false, p_collision_point: Vector2 = Vector2.ZERO, p_bounce_vector: Vector2 = Vector2.ZERO):
		is_valid = p_is_valid
		collision_point = p_collision_point
		bounce_vector = p_bounce_vector


func _ready():
	for child in coll_rays_node.get_children():
		if child is RayCast2D:
			coll_ray_arr.append(child)
	
	for ray in coll_ray_arr:
		start_y_target_dict[ray] = ray.target_position.y
	
	
	velocity = Vector2(0,0)


func _physics_process(delta):
	
	if disabled: return
	
	has_bounced_this_frame = false
	
	# Apply gravity to velocity
	velocity.y += gravity * delta
	
	# Calculate movement for this frame
	var move_vec: Vector2 = velocity * delta
	
	# get coll data
	var coll_result: CollData = run_coll_check(move_vec)
	#print( "-------- \r coll_result.is_valid ",coll_result.is_valid)
	#print( "coll_result.bounce_vector ",coll_result.bounce_vector)
	#print( "coll_result.collision_point ",coll_result.collision_point)
	#print("is sliding: ",is_sliding)
	
	if is_in_air(): 
		air_time += delta
		if air_time > 0.33:
			set_is_sliding(false)
	else:
		air_time = 0
	
	for i in max_bounces_per_frame:
		if coll_result.is_valid:
			has_bounced_this_frame = true
			perform_collision(coll_result,delta)
		else:
			break
	
	
	# Apply straight movement if there has been no bounce
	if not has_bounced_this_frame:
		var final_move_vec: Vector2 = velocity * delta
		global_position += final_move_vec
	
	
	var dist_to_last_frame: float = global_position.distance_to(last_frame_pos)
	
	if dist_to_last_frame <= 1:
		inactive_time += delta
		if inactive_time > 10:
			set_disabled(true)
			inactive_time = 0
	
	last_frame_pos = global_position

func run_coll_check(move_vec: Vector2):
	
	_hit_normal_dict.clear()
	_hit_point_dict.clear()
	_hit_pegs.clear()
	
	var hit_vec_sum: Vector2 = Vector2.ZERO
	var average_hit_vec: Vector2 = Vector2.ZERO
	
	var curr_closest_hit_dist: float =  1.79769e308
	var closest_hit_point: Vector2 = Vector2.ZERO
	
	var bounce_vec: Vector2 = Vector2.ZERO
	var collision_point: Vector2 = Vector2.ZERO
	
	
	# Point rays in movement direction
	_look_at_vector = global_position + move_vec.rotated(-PI/2)
	coll_rays_node.look_at(_look_at_vector)
	
	# Extend ray length based on movement distance
	for ray in coll_ray_arr:
		ray.target_position.y = start_y_target_dict[ray] + move_vec.length()
	
	# Check all rays for collisions
	for coll_ray in coll_ray_arr:
		coll_ray.force_raycast_update()
		if coll_ray.is_colliding():
			
			var hit_area: Area2D = coll_ray.get_collider()
			var coll_normal: Vector2 = coll_ray.get_collision_normal()
			var coll_point: Vector2 = coll_ray.get_collision_point()
			
			if hit_area is DestructiblePeg and not _hit_pegs.has(hit_area):
				_hit_pegs.append(hit_area)
			
			if _hit_normal_dict.has(hit_area):
				_hit_normal_dict[hit_area].append(coll_normal)
			else:
				_hit_normal_dict[hit_area] = [coll_normal]
			
			if _hit_point_dict.has(hit_area):
				_hit_point_dict[hit_area].append(coll_point)
			else:
				_hit_point_dict[hit_area] = [coll_point]
	
	if _hit_normal_dict.is_empty() or _hit_point_dict.is_empty():
		_coll_data.is_valid = false
		#print("Collision Error! _hit_normal_dict.is_empty() or _hit_point_dict.is_empty()")
		return _coll_data
	
	# Average collision normals
	for key in _hit_normal_dict.keys():
		var arr: Array = _hit_normal_dict[key]
		var sum_vec: Vector2 = Vector2.ZERO
		for vec in arr:
			sum_vec += vec
		var average_vec = sum_vec / arr.size()
		hit_vec_sum += average_vec
	
	average_hit_vec = hit_vec_sum / _hit_normal_dict.keys().size()
	
	if average_hit_vec == Vector2.ZERO:
		_coll_data.is_valid = false
		#print("Collision Error! average_hit_vec == Vector2.ZERO")
		return _coll_data
	
	# closest collision point
	for key in _hit_point_dict.keys():
		var arr: Array = _hit_point_dict[key]
		var sum_vec: Vector2 = Vector2.ZERO
		for vec in arr:
			sum_vec += vec
		var object_average_pos = sum_vec / arr.size()
		var dist_to_object_average: float = global_position.distance_to(object_average_pos)
		
		#add_debug_circle(object_average_pos,Color.REBECCA_PURPLE)
		
		if dist_to_object_average < curr_closest_hit_dist:
			curr_closest_hit_dist = dist_to_object_average
			closest_hit_point = object_average_pos
		
	
	
	
	# get bounce direction
	bounce_vec = move_vec.bounce(average_hit_vec.normalized()).normalized()
	
	#find difference from bounce directon to the current velocity dir
	var dif_to_vel: float = bounce_vec.distance_to(velocity.normalized())
	
	# go along surface if its similar to the current velocity direction
	if dif_to_vel < slipperiness:
		
		# dont slide if the ball is already moving the right way
		if dif_to_vel < 0.01:
			_coll_data.is_valid = false
			return _coll_data
		
		set_is_sliding(true)
		# going along the surface and slightly up so the ball doesnt drag along it
		var slide_velocity = velocity - average_hit_vec * velocity.dot(average_hit_vec)
		slide_velocity += average_hit_vec * 50000/velocity.length()
		
		
		queue_pegs_for_destruction(_hit_pegs)
		_coll_data.bounce_vector = slide_velocity.normalized()
		_coll_data.collision_point = closest_hit_point
		_coll_data.is_valid = true
		return _coll_data
		
	#else:
		#set_is_sliding(false)
	
	queue_pegs_for_destruction(_hit_pegs)
	_coll_data.bounce_vector = bounce_vec
	_coll_data.collision_point = closest_hit_point
	_coll_data.is_valid = true
	return _coll_data

@warning_ignore("unused_parameter")
func perform_collision(collision_data: CollData,delta: float):
	if not collision_data.is_valid: return
	
	var speed = velocity.length()
	
	#if is_sliding:
		#speed -= slide_drag * delta
		#speed = clampf(speed,1,5000)
	
	velocity = collision_data.bounce_vector.normalized() * speed
	
	#if velocity.length() < 20:
		#return
	
	var coll_pos: Vector2 = collision_data.collision_point - global_position.direction_to(collision_data.collision_point)*15
	global_position = coll_pos
	
	#$Line2D.add_point(coll_pos)
	#add_debug_circle(coll_pos)
	
	if not is_sliding:
		velocity *= bounciness


func is_in_air() -> bool:
	
	for ray in coll_ray_arr:
		if ray.is_colliding():
			return false
	
	return true

func queue_pegs_for_destruction(pegs: Array[DestructiblePeg]):
	for peg in pegs:
		peg.queue_destruction()


func set_is_sliding(new_is_sliding: bool):
	is_sliding = new_is_sliding
	match is_sliding:
		true:
			ball_sprite_node.modulate = Color.RED
		false:
			ball_sprite_node.modulate = Color.WHITE

func set_disabled(new_disabled: bool):
	disabled = new_disabled
	match disabled:
		true:                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
			hide()
		false:
			show()



func add_debug_circle(pos: Vector2, cmodulate: Color = Color.WHITE):
	var debug_sq := Sprite2D.new()
	get_tree().root.add_child(debug_sq)
	debug_sq.texture = load("res://2D/godot_gen_textures/debug_circle.tres")
	debug_sq.scale = Vector2.ONE 
	debug_sq.modulate = cmodulate
	debug_sq.global_position = pos
