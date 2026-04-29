extends Node2D


var start_speed: float = 700
 
@onready var ball_spawn_point: Node2D = $pivot/ball_spawn_point

@export var test_upgrade: UpgradeData

var delta_timer: float = 0
var shot_interval: float = 0.6

var upgrade_preloader: ResourcePreloader

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.upgrade_preloader_loaded.connect(_on_upgrade_preloader_loaded)
	

func _on_upgrade_preloader_loaded(preloader: ResourcePreloader):
	upgrade_preloader = preloader


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	delta_timer += delta
	
	$pivot.look_at(get_global_mouse_position())
	$pivot.rotate(-PI/2)
	
	
	var speed_upgrade: UpgradeData = upgrade_preloader.get_resource("ball_speed")
	var speed_level: int = SaveManager.get_upgrade_level_by_name("ball_speed")
	
	start_speed = speed_upgrade.get_level_price(speed_level)
	
	var pos = ball_spawn_point.global_position
	var vel = global_position.direction_to(ball_spawn_point.global_position) * start_speed
	var radius = 16.0
	
	if sin(delta_timer*(1/delta))>0:
		SignalBus.spawn_simulated_ball.emit(pos,vel,radius)
	
	
	if Input.is_action_just_pressed("fire_ball"):
	#if delta_timer >= shot_interval:
		delta_timer = 0
		SignalBus.spawn_ball.emit(pos,vel,radius)
