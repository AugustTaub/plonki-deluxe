extends Node2D

var gravity: float = 1500

var bounciness: float = 0.9

var velocity: Vector2 = Vector2.ZERO

var coll_circle_segments: int = 32
var coll_move_substeps: int = 4


@onready var coll_ray: RayCast2D = $coll_ray
@onready var standard_ray_target: Vector2 = coll_ray.target_position


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	velocity.y += gravity * delta
	
	
	attempt_move_with_substeps(velocity * delta)
	
	global_position += velocity * delta


func attempt_move_with_substeps(move_vec: Vector2):
	for step_i in coll_move_substeps:
		var bounced_vec: Vector2 = attempt_move(move_vec/coll_move_substeps)
		if bounced_vec != Vector2.ZERO:
			velocity = bounced_vec
			return
		else:
			return
		


func attempt_move(move_vec: Vector2):
	coll_ray.global_position += move_vec
	var hit_dict: Dictionary[Area2D,Array]
	
	var hit_vec_sum: Vector2 = Vector2.ZERO
	var average_hit_vec: Vector2 = Vector2.ZERO
	var result_vec: Vector2 = Vector2.ZERO
	
	coll_ray.target_position = standard_ray_target
	for i in range(coll_circle_segments):
		var split: float = 360.0/coll_circle_segments
		
		coll_ray.target_position = standard_ray_target.rotated(deg_to_rad(i*split))
		
		coll_ray.force_raycast_update()
		if coll_ray.is_colliding():
			var hit_area: Area2D = coll_ray.get_collider()
			var coll_normal: Vector2 = coll_ray.get_collision_normal()
			if hit_dict.has(hit_area):
				hit_dict[hit_area].append(coll_normal)
			else:
				hit_dict[hit_area] = [coll_normal]
	
	coll_ray.global_position -= move_vec
	if hit_dict.is_empty(): return result_vec
	
	
	
	
	for key in hit_dict.keys():
		var arr: Array = hit_dict[key]
		var sum_vec: Vector2 = Vector2.ZERO
		for vec in arr:
			sum_vec += vec
		var average_vec = sum_vec / arr.size()
		hit_vec_sum += average_vec
	
	average_hit_vec = hit_vec_sum / hit_dict.keys().size()
	
	if average_hit_vec == Vector2.ZERO: return result_vec
	
	result_vec = velocity.bounce(average_hit_vec.normalized())
	
	return result_vec
	#velocity = result_vec 
