extends Node2D


var start_speed: float = 700
 
@onready var ball_spawn_point: Node2D = $pivot/ball_spawn_point

@export var test_upgrade: UpgradeData

@export var infested_peg_manager: InfestedPegManager

@export var simulated_ball_frequency: float = 0.1
@export var auto_fire_hold_time: float = 0.3

var last_frame_mouse_pos: Vector2 = Vector2.ZERO
var mouse_has_moved_this_frame: bool = false

var fire_button_held_time: float = 0

var time_since_last_shot: float = 0
var time_since_last_sim_shot: float = 0

var shot_interval: float = 0.05

@onready var shot_particles_one: GPUParticles2D = %shot_particles_one
@onready var shot_particles_more: GPUParticles2D = %shot_particles_more




var upgrade_preloader: ResourcePreloader

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.upgrade_preloader_loaded.connect(_on_upgrade_preloader_loaded)
	%enemy_dodge_beam.area_shape_entered.connect(_on_enemy_dodge_beam_area_entered)

func _on_upgrade_preloader_loaded(preloader: ResourcePreloader):
	upgrade_preloader = preloader



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	
	# counting up timers
	time_since_last_shot += delta
	time_since_last_sim_shot += delta
	
	look_at_mouse()
	
	
	var speed_upgrade: UpgradeData = upgrade_preloader.get_resource("ball_speed")
	var speed_level: int = SaveManager.get_upgrade_level_by_name("ball_speed")
	
	start_speed = speed_upgrade.get_level_result(speed_level)
	
	var radius_upgrade: UpgradeData = upgrade_preloader.get_resource("ball_size")
	var radius_level: int = SaveManager.get_upgrade_level_by_name("ball_size")
	
	var radius = radius_upgrade.get_level_result(radius_level)
	
	
	# final assignments
	var pos = ball_spawn_point.global_position
	var vel = global_position.direction_to(ball_spawn_point.global_position) * start_speed
	
	if mouse_has_moved_this_frame or time_since_last_sim_shot > simulated_ball_frequency:
		SignalBus.spawn_simulated_ball.emit(pos,vel,radius)
		time_since_last_sim_shot = 0.0
	
	
	###Input checks
	
	# held timer
	if Input.is_action_pressed("fire_ball"):
		fire_button_held_time += delta
	else:
		fire_button_held_time = 0
	
	
	# looking if mouse has moved
	var mpos: Vector2 = get_global_mouse_position()
	
	if last_frame_mouse_pos != mpos:
		mouse_has_moved_this_frame = true
	else:
		mouse_has_moved_this_frame = false
	
	last_frame_mouse_pos = mpos
	
	
	
	var has_held_long_enough: bool = fire_button_held_time > auto_fire_hold_time
	var fire_input_accepted: bool = Input.is_action_just_pressed("fire_ball") or has_held_long_enough
	
	var ball_available: bool = BallFactoryManager.has_balls()
	
	if fire_input_accepted and ball_available and GlobalVars.mouse_is_in_play_area and time_since_last_shot >= shot_interval:
	#if time_since_last_shot >= shot_interval:
		var anim_spd: float = 1.0
		var volume_mod: float = 1.0
		
		if time_since_last_shot < 1.0:
			anim_spd /= time_since_last_shot
		
		
		if time_since_last_shot < 0.1:
			volume_mod = 0.5
		
		%cannon_sprite.play("default",anim_spd)
		
		SignalBus.play_sound.emit("blup",volume_mod)
		
		if shot_particles_one.emitting:
			shot_particles_more.emitting = true
		else:
			shot_particles_one.emitting = true
		
		var prod_upgrade: UpgradeData = upgrade_preloader.get_resource("ball_production_speed")
		var prod_level: int = SaveManager.get_upgrade_level_by_name("ball_production_speed")
		
		var curr_max_shot_speed: float = prod_upgrade.get_level_result(prod_level)
		
		#multi shot when shooting faster than physics frame rate
		if  curr_max_shot_speed < delta:
			var dir: Vector2 =  $pivot.global_transform.x
			
			var extra_shots: int = max( ( int(delta/curr_max_shot_speed) ), 2)
			print(extra_shots)
			for e in extra_shots:
				var pos_add: Vector2 = dir*8*e* int(1 if randf() else -1)
				SignalBus.spawn_ball.emit(pos+pos_add,vel,radius)
				BallFactoryManager.remove_last_ball_from_queue()
			
		else:
			SignalBus.spawn_ball.emit(pos,vel,radius)
			BallFactoryManager.remove_last_ball_from_queue()
		
		time_since_last_shot = 0.0
		

	
	if Input.is_action_just_released("fire_ball") or not BallFactoryManager.has_balls():
		shot_particles_more.emitting = false
	

func _on_enemy_dodge_beam_area_entered(area_rid: RID, _area: Area2D, _area_shape_index: int, _local_shape_index: int) -> void:
	if not infested_peg_manager:
		push_warning("BallCannon: no infested peg manager attached!")
		return
	
	
	var id_str: String = infested_peg_manager.get_peg_area_id_from_rid(area_rid)
	
	if id_str != "":
		var id: int = id_str.to_int()
		
		
		if id >= 0 and id < infested_peg_manager.active_pegs.size():
			var hit_peg: InfestedPegManager.PegData = infested_peg_manager.active_pegs[id]
			
			var fear_high_enough: bool = hit_peg.fear > 85
			
			if hit_peg.active and fear_high_enough and not hit_peg.has_eaten:
				infested_peg_manager.change_peg_state(hit_peg, "dodging")
				hit_peg.danger_dir = -get_direction_to_line_2d(hit_peg.pos, global_position, Vector2.UP.rotated($pivot.global_rotation))
	

func look_at_mouse():
	# rotating the cannon
	$pivot.look_at(get_global_mouse_position())
	$pivot.rotate(-PI/2)



func get_direction_to_line_2d(point: Vector2, line_point: Vector2, line_dir: Vector2) -> Vector2:
	var v = line_dir.normalized()
	var ap = point - line_point
	
	var t = ap.dot(v)
	
	var closest_point = line_point + (v * t)
	
	return (closest_point - point).normalized()
