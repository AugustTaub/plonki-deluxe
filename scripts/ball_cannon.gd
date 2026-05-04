extends Node2D


var start_speed: float = 700
 
@onready var ball_spawn_point: Node2D = $pivot/ball_spawn_point

@export var test_upgrade: UpgradeData

var time_since_last_shot: float = 0
var shot_interval: float = 0.6

var upgrade_preloader: ResourcePreloader

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.upgrade_preloader_loaded.connect(_on_upgrade_preloader_loaded)
	

func _on_upgrade_preloader_loaded(preloader: ResourcePreloader):
	upgrade_preloader = preloader


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	time_since_last_shot += delta
	
	$pivot.look_at(get_global_mouse_position())
	$pivot.rotate(-PI/2)
	
	
	var speed_upgrade: UpgradeData = upgrade_preloader.get_resource("ball_speed")
	var speed_level: int = SaveManager.get_upgrade_level_by_name("ball_speed")
	
	start_speed = speed_upgrade.get_level_result(speed_level)
	
	var radius_upgrade: UpgradeData = upgrade_preloader.get_resource("ball_size")
	var radius_level: int = SaveManager.get_upgrade_level_by_name("ball_size")
	
	var radius = radius_upgrade.get_level_result(radius_level)
	#print("radius: ",radius)
	
	var pos = ball_spawn_point.global_position
	var vel = global_position.direction_to(ball_spawn_point.global_position) * start_speed
	
	
	if sin(time_since_last_shot*(1/delta))>0:
		SignalBus.spawn_simulated_ball.emit(pos,vel,radius)
	
	
	if Input.is_action_just_pressed("fire_ball") and BallFactoryManager.has_balls():
	#if time_since_last_shot >= shot_interval:
		var anim_spd: float = 1
		
		if time_since_last_shot < 1:
			anim_spd /= time_since_last_shot
		
		%cannon_sprite.play("default",anim_spd)
		
		time_since_last_shot = 0
		SignalBus.spawn_ball.emit(pos,vel,radius)
		BallFactoryManager.remove_last_ball_from_queue()
