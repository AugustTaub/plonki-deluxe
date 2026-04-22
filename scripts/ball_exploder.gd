extends BallInteractibleObject

class_name BallExploder
var is_dead: bool = false

var delta_timer: float = 0
var revive_timer: float = 1

var explode_strength: float = 1200
@export var explo_area: Area2D
@export var sprite: Sprite2D

func _physics_process(delta: float) -> void:
	if is_dead: delta_timer += delta
	
	if delta_timer >= revive_timer:
		delta_timer = 0
		revive()


func perform_interaction(ball_data: BallManager.BallData) -> BallManager.BallData:
	if is_dead: return
	
	if explo_area and not ball_data.simulated:
		destroy()
		var found_areas: Array = explo_area.get_overlapping_areas()
		for found_area in found_areas:
			if found_area is DestructiblePeg:
				found_area.destroy()
	
	
	var to_dir: Vector2 = global_position.direction_to(ball_data.pos)
	ball_data.vel = to_dir * explode_strength
	return ball_data

func revive():
	if not is_dead: return
	
	is_dead = false
	
	if sprite:
		sprite.modulate = Color.WHITE
		var tween = create_tween()
		tween.tween_property(sprite,"scale",Vector2.ONE ,0.1).set_trans(Tween.TRANS_BOUNCE)

func destroy():
	if is_dead: return
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite,"scale",Vector2.ONE * 1.9,0.05)
		tween.tween_property(sprite,"scale",Vector2.ONE * 0.001,0.05).set_trans(Tween.TRANS_BOUNCE)
		sprite.modulate = Color.DIM_GRAY
	
	is_dead = true
