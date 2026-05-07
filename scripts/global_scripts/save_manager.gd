extends Node

const SAVE_PATH := "user://plonki_save2fgd895teho.tres"

var save_game: SaveGame = null

var upgrade_preloader: ResourcePreloader

var delta_timer: float = 0
var auto_save_time: float = 1

func _ready() -> void:
	
	var new_save: bool = false
	
	if ResourceLoader.exists(SAVE_PATH):
		save_game = ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	else:
		save_game = SaveGame.new()
		new_save = true
	
	await get_tree().create_timer(0).timeout
	SignalBus.upgrade_preloader_loaded.connect(_on_upgrade_preloader_loaded)

	if upgrade_preloader and new_save:
		for res_name in upgrade_preloader.get_resource_list():
				var res: UpgradeData = upgrade_preloader.get_resource(res_name)
				if res is UpgradeData:
					save_game.upgrade_levels[res] = 0
		
	
	set_money(save_game.money_amount)
	
	

func _process(delta: float) -> void:
	delta_timer += delta
	if delta_timer > auto_save_time:
		delta_timer = 0
		ResourceSaver.save(save_game, SAVE_PATH)



func _on_upgrade_preloader_loaded(preloader: ResourcePreloader):
	upgrade_preloader = preloader

func set_money(new_money: int):
	save_game.money_amount = new_money
	SignalBus.set_money_counter.emit(new_money)
	

func change_money(change_amount: int):
	set_money(save_game.money_amount+change_amount)

func set_ball_amount(new_amount: int):
	save_game.ball_amount = new_amount


func add_upgrade(new_upgrade: UpgradeData):
	if not save_game.unlocked_upgrades.has(new_upgrade):
		save_game.unlocked_upgrades.append(new_upgrade)
		save_game.upgrade_levels[new_upgrade] = 0
	

func increase_upgrade_level(increase_upgrade: UpgradeData):
	
	if save_game.upgrade_levels.has(increase_upgrade):
		
		var new_val: int = save_game.upgrade_levels[increase_upgrade] + 1
		
		if new_val <= increase_upgrade.max_level:
			save_game.upgrade_levels[increase_upgrade] = new_val
	else:
		save_game.upgrade_levels[increase_upgrade] = 0
	

func set_upgrade_level(set_upgrade: UpgradeData, new_level: int):
	if save_game.unlocked_upgrades.has(set_upgrade):
		new_level = clamp(new_level,0,set_upgrade.max_level)
		save_game.upgrade_levels[set_upgrade] = new_level


func get_unlocked_upgrade_by_name(upgrade_name: String):
	for upgrade in save_game.unlocked_upgrades:
		if upgrade.name == upgrade_name:
			return upgrade

func get_upgrade_level_by_name(upgrade_name: String):
	var get_upgrade: UpgradeData = SaveManager.get_unlocked_upgrade_by_name(upgrade_name)
	var upgrade_level
	
	
	if SaveManager.save_game.upgrade_levels.has(get_upgrade) and get_upgrade != null:
		upgrade_level = SaveManager.save_game.upgrade_levels[get_upgrade]
	else:
		upgrade_level = 0
	
	return upgrade_level
