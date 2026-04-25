extends Node

const SAVE_PATH := "user://plonki_save.tres"

var save_game: SaveGame = null


func _ready() -> void:
	
	if ResourceLoader.exists(SAVE_PATH):
		save_game = ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	else:
		save_game = SaveGame.new()
	
	
	set_money(save_game.money_amount)


func set_money(new_money: int):
	save_game.money_amount = new_money
	SignalBus.set_money_counter.emit(new_money)

func add_upgrade(new_upgrade: int):
	if not save_game.unlocked_upgrades.has(new_upgrade):
		save_game.unlocked_upgrades.append(new_upgrade)
