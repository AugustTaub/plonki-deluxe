extends Node2D


var start_speed: float = 700
 
@onready var ball_spawn_point: Node2D = $pivot/ball_spawn_point

@export var test_upgrade: UpgradeData

@export var simulated_ball_frequency: float = 0.1

var last_frame_mouse_pos: Vector2 = Vector2.ZERO
var mouse_has_moved_this_frame: bool = false

var time_since_last_shot: float = 0
var time_since_last_sim_shot: float = 0

var shot_interval: float = 0.1

var upgrade_preloader: ResourcePreloader

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.upgrade_preloader_loaded.connect(_on_upgrade_preloader_loaded)
	

func _on_upgrade_preloader_loaded(preloader: ResourcePreloader):
	upgrade_preloader = preloader


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	time_since_last_shot += delta
	time_since_last_sim_shot += delta
	
	var mpos: Vector2 = get_global_mouse_position()
	if last_frame_mouse_pos != mpos:
		mouse_has_moved_this_frame = true
	else:
		mouse_has_moved_this_frame = false
	
	last_frame_mouse_pos = mpos
	
	
	
	$pivot.look_at(get_global_mouse_position())
	$pivot.rotate(-PI/2)
	
	
	var speed_upgrade: UpgradeData = upgrade_preloader.get_resource("ball_speed")
	var speed_level: int = SaveManager.get_upgrade_level_by_name("ball_speed")
	
	start_speed = speed_upgrade.get_level_result(speed_level)
	
	var radius_upgrade: UpgradeData = upgrade_preloader.get_resource("ball_size")
	var radius_level: int = SaveManager.get_upgrade_level_by_name("ball_size")
	
	var radius = radius_upgrade.get_level_result(radius_level)
	
	var pos = ball_spawn_point.global_position
	var vel = global_position.direction_to(ball_spawn_point.global_position) * start_speed
	
	
	if mouse_has_moved_this_frame or time_since_last_sim_shot > simulated_ball_frequency:
		SignalBus.spawn_simulated_ball.emit(pos,vel,radius)
		time_since_last_shot = 0.0
	
	
	if Input.is_action_just_pressed("fire_ball") and BallFactoryManager.has_balls() and GlobalVars.mouse_is_in_play_area:
	#if time_since_last_shot >= shot_interval:
		var anim_spd: float = 1
		
		if time_since_last_shot < 1:
			anim_spd /= time_since_last_shot
		
		%cannon_sprite.play("default",anim_spd)
		
		time_since_last_shot = 0
		SignalBus.spawn_ball.emit(pos,vel,radius)
		BallFactoryManager.remove_last_ball_from_queue()
