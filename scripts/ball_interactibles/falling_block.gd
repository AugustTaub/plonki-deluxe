extends BallInteractibleObject

class_name BallInteractibleFallingBlock

@export var sprite: Sprite2D
@export var falling_area: Area2D

var is_falling: bool = false

var grav: float = 400

var delta_timer: float = 0

var respawn_time: float = 1

func _physics_process(delta):
	if is_falling:
		falling_area.global_position.y += delta * grav
		sprite.global_position.y += delta * grav
		
		delta_timer += delta
		
		if delta_timer > 0.2:
			delta_timer = 0
			SignalBus.spawn_shock_wave.emit(sprite.global_position,160*2,0.1)
			
			if falling_area:
				var areas = falling_area.get_overlapping_areas()
				for area in areas:
					if area is DestructiblePeg:
						area.destroy()
					
					if area is KillZone:
						await get_tree().create_timer(respawn_time).timeout
						reset()


func perform_interaction(ball_data: BallManager.BallData) -> BallManager.BallData:
	if ball_data.simulated: return
	is_falling = true
	
	
	return ball_data


func reset():
	falling_area.global_position = global_position
	sprite.global_position = global_position
	is_falling = false
