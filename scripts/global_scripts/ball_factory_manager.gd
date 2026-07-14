extends Node

var queued_balls: Array[float] = []

var ball_spawn_cooldown: float = 1.0

var max_number_of_queued_balls: int = 999

var delta_timer: float = 0

var upgrade_preloader: ResourcePreloader


signal new_ball_produced(radius: float)
signal last_ball_removed()

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.upgrade_preloader_loaded.connect(_on_upgrade_preloader_loaded)
	

func _on_upgrade_preloader_loaded(preloader: ResourcePreloader):
	upgrade_preloader = preloader

func _physics_process(delta: float) -> void:
	delta_timer += delta
	if delta_timer > ball_spawn_cooldown and upgrade_preloader:
		
		var radius_upgrade: UpgradeData = upgrade_preloader.get_resource("ball_size")
		var radius_level: int = SaveManager.get_upgrade_level_by_name("ball_size")
		var radius = radius_upgrade.get_level_result(radius_level)
		
		add_ball_to_queue(radius)
		delta_timer = 0


func add_ball_to_queue(radius: float):
	
	if queued_balls.size() == max_number_of_queued_balls:
		return
	
	queued_balls.append(radius)
	
	update_ball_amount()
	
	new_ball_produced.emit(radius)

func remove_last_ball_from_queue():
	queued_balls.pop_back()
	
	update_ball_amount()
	
	last_ball_removed.emit()

func update_ball_amount():
	var amount: int = queued_balls.size()
	SignalBus.set_ball_counter.emit(amount)
	SaveManager.set_ball_amount(amount)


func has_balls() -> bool:
	if queued_balls.size() > 0:
		return true
	else:
		return false
