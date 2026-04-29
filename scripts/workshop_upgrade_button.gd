extends Button

@export var associated_upgrade: UpgradeData


# Called when the node enters the scene tree for the first time.
func _ready():
	if associated_upgrade:
		await get_tree().create_timer(0).timeout
		update_visuals_from_save_game()
	else:
		push_warning("no valid associated_upgrade for upgrade button!")
		


func _on_pressed():
	if associated_upgrade:
		
		
		if SaveManager.save_game.unlocked_upgrades.has(associated_upgrade):
			
			if SaveManager.save_game.upgrade_levels[associated_upgrade]+1 > associated_upgrade.max_level:
				return
			
			
			var curr_lvl
			if SaveManager.save_game.upgrade_levels.has(associated_upgrade):
				curr_lvl = SaveManager.save_game.upgrade_levels[associated_upgrade]
			else:
				curr_lvl = 0
			
			var price: int = associated_upgrade.get_level_price(curr_lvl)
			
			if price <= SaveManager.save_game.money_amount:
				SaveManager.change_money(-price)
			else:
				return
			
			SaveManager.increase_upgrade_level(associated_upgrade)
		else:
			SaveManager.add_upgrade(associated_upgrade)
		
		update_visuals_from_save_game()

func update_visuals_from_save_game():
	if not associated_upgrade: return
	
	var curr_lvl
	
	if SaveManager.save_game.upgrade_levels.has(associated_upgrade):
		curr_lvl = SaveManager.save_game.upgrade_levels[associated_upgrade]
	else:
		curr_lvl = 0
	
	# cost
	if curr_lvl < associated_upgrade.max_level:
		var cost = associated_upgrade.get_level_price(curr_lvl)
		%cost_text.text = str(cost)
	else:
		$cost_text_container.hide()
	
	# level
	var max_lvl: String = str(associated_upgrade.max_level)
	
	text = str(curr_lvl) + "/" + max_lvl
	
	# hint text
	if curr_lvl < associated_upgrade.max_level:
		var curr_value: float = associated_upgrade.get_level_result(curr_lvl)
		var next_value: float = associated_upgrade.get_level_result(curr_lvl+1)
		
		%hint_text.text = associated_upgrade.name + "\r" + str(round(curr_value)) + " -> " + str(round(next_value))
	else:
		%hint_text.text = associated_upgrade.name + "\r [fully upgraded]" 


func _on_mouse_entered():
	$hint_panel.show()


func _on_mouse_exited():
	$hint_panel.hide()
