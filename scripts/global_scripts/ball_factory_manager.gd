extends Node

var queued_balls: Array[float] = []
var ball_spawn_cooldown: float = 2.0
var max_number_of_queued_balls: int = 42
var delta_timer: float = 0.0

var upgrade_preloader: ResourcePreloader

signal new_ball_produced(radius: float)
signal last_ball_removed()

func _ready() -> void:
	SignalBus.upgrade_preloader_loaded.connect(_on_upgrade_preloader_loaded)
	
	await SignalBus.upgrade_preloader_loaded
	
	if upgrade_preloader.has_resource("ball_production_speed"):
		var cd_upgrade: UpgradeData = upgrade_preloader.get_resource("ball_production_speed")
		var cd_level: int = SaveManager.get_upgrade_level_by_name("ball_production_speed")
		var cd: float = cd_upgrade.get_level_result(cd_level)
		
		ball_spawn_cooldown = cd
	

func _on_upgrade_preloader_loaded(preloader: ResourcePreloader) -> void:
	upgrade_preloader = preloader

func _physics_process(delta: float) -> void:
	delta_timer += delta
	
	#add ball to save
	if delta_timer >= ball_spawn_cooldown:
		delta_timer = 0.0
		
		if upgrade_preloader:
			var cd_upgrade: UpgradeData = upgrade_preloader.get_resource("ball_production_speed")
			var cd_level: int = SaveManager.get_upgrade_level_by_name("ball_production_speed")
			var cd: float = cd_upgrade.get_level_result(cd_level)
			
			ball_spawn_cooldown = cd
		
		SignalBus.emit_signal("ball_just_generated")
		
		update_ball_amount(SaveManager.save_game.ball_amount + 1)
		
	
	# spawn physical ball if possible
	if upgrade_preloader and can_spawn_ball():
		var radius_upgrade: UpgradeData = upgrade_preloader.get_resource("ball_size")
		var radius_level: int = SaveManager.get_upgrade_level_by_name("ball_size")
		var radius: float = radius_upgrade.get_level_result(radius_level)
		
		call_deferred("add_ball_to_queue",radius)

func can_spawn_ball() -> bool:
	return queued_balls.size() < max_number_of_queued_balls and SaveManager.save_game.ball_amount > 0

func add_ball_to_queue(radius: float) -> void:
	if not can_spawn_ball():
		return
		
	queued_balls.append(radius)
	
	var new_amount: int = SaveManager.save_game.ball_amount - 1
	update_ball_amount(new_amount)
	
	new_ball_produced.emit(radius)

func remove_last_ball_from_queue(refund_to_save: bool = false) -> void:
	if queued_balls.is_empty():
		return
	
	queued_balls.pop_back()
	
	if refund_to_save:
		var new_amount: int = max(0, SaveManager.save_game.ball_amount + 1)
		update_ball_amount(new_amount)
	
	last_ball_removed.emit()


func update_ball_amount(amount: int) -> void:
	SaveManager.set_ball_amount(amount)
	SignalBus.set_ball_counter.emit(amount)

func has_balls() -> bool:
	return queued_balls.size() > 0
