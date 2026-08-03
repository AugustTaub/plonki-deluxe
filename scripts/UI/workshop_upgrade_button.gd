extends Button

class_name WorkshopUpgradeButton

@export var associated_upgrade: UpgradeData

@export var required_upgrade: UpgradeData

@onready var hint_panel: Control = $hint_panel
@onready var start_pos: Vector2 = global_position

var required_arrow_goal: Vector2 

func _ready() -> void:
	if not associated_upgrade:
		push_warning("No valid associated_upgrade for upgrade button!")
	
	if required_upgrade:
		draw_required_arrow()

func _on_pressed() -> void:
	if not associated_upgrade:
		return
	
	
	if not SaveManager.save_game.unlocked_upgrades.has(associated_upgrade):
		SaveManager.add_upgrade(associated_upgrade)
	
	var curr_lvl: int = SaveManager.save_game.upgrade_levels.get(associated_upgrade, 0)
	
	if curr_lvl >= associated_upgrade.max_level:
		return
	
	var price: int = associated_upgrade.get_level_price(curr_lvl)
	
	var has_requirements: bool = true
	
	if required_upgrade:
		if SaveManager.save_game.unlocked_upgrades.has(required_upgrade):
			has_requirements = true
		else:
			has_requirements = false
	
	if has_requirements:
		if SaveManager.save_game.money_amount >= price:
			SaveManager.change_money(-price)
			SaveManager.increase_upgrade_level(associated_upgrade)
			update_visuals_from_save_game()
			
			SignalBus.play_sound.emit("paid",1.2)
			
			buy_anim()
		else:
			too_expensive_anim()
	else:
		too_expensive_anim()
	


func update_visuals_from_save_game() -> void:
	if not associated_upgrade:
		return
	
	if required_upgrade:
		if not SaveManager.save_game.unlocked_upgrades.has(required_upgrade):
			self_modulate = Color.DIM_GRAY
		else:
			self_modulate = Color.WHITE
	
	var curr_lvl: int = SaveManager.save_game.upgrade_levels.get(associated_upgrade, 0)
	
	# cost display
	if curr_lvl < associated_upgrade.max_level:
		var cost: int = associated_upgrade.get_level_price(curr_lvl)
		if has_node("%cost_text"):
			%cost_text.text = MoneyTextShortener.amount_to_string(cost)
			
		if has_node("cost_text_container"):
			$cost_text_container.show()
	else:
		if has_node("cost_text_container"):
			$cost_text_container.hide()
	
	# level display
	text = str(curr_lvl) + "/" + str(associated_upgrade.max_level)
	
	# hint text display
	if has_node("%hint_text"):
		
		#return early if required upgrade is missing
		if required_upgrade:
			if not SaveManager.save_game.unlocked_upgrades.has(required_upgrade):
				%hint_text.text = "You have to buy: " + required_upgrade.name + " first!"
				return
		
		
		if curr_lvl < associated_upgrade.max_level:
			var curr_value: float = associated_upgrade.get_level_result(curr_lvl)
			var next_value: float = associated_upgrade.get_level_result(curr_lvl + 1)
			
			var r_curr_value: float = adaptive_round(curr_value)
			var r_next_value: float = adaptive_round(next_value)
			
			%hint_text.text = associated_upgrade.pretty_name + "\r" + str(r_curr_value) + " -> " + str(r_next_value) + " " + associated_upgrade.unit
			
		else:
			%hint_text.text = associated_upgrade.pretty_name + "\r [fully upgraded]"

func set_button_disabled(button_disabled: bool) -> void:
	disabled = button_disabled
	
	if button_disabled:
		text = ""
		if has_node("cost_text_container"):
			$cost_text_container.hide()
	else:
		if has_node("cost_text_container"):
			$cost_text_container.show()
		update_visuals_from_save_game()

###

func too_expensive_anim():
	
	var tween: Tween = create_tween()
	tween.tween_property(self,"global_position:x",global_position.x + 5,0.05)
	tween.tween_property(self,"global_position:x",global_position.x + -10,0.05)
	tween.tween_property(self,"global_position:x",start_pos.x,0.05)
	

func buy_anim():

	var tween: Tween = create_tween()
	tween.tween_property(self,"scale", Vector2.ONE * 1.2, 0.05)
	tween.tween_property(self,"scale", Vector2.ONE, 0.1)


###

func adaptive_round(value: float) -> float:
	if value < 10.0:
		return snapped(value, 0.01)
	if value < 100.0:
		return snapped(value, 0.1)
	return snapped(value, 1.0)

func draw_required_arrow() -> void:
	var button_parent: Control = get_parent()
	var siblings: Array = button_parent.get_children()
	
	for sibling in siblings:
		if sibling is WorkshopUpgradeButton and sibling.associated_upgrade == required_upgrade:
			
			required_arrow_goal = sibling.global_position
			
			sibling.pressed.connect(func(): update_visuals_from_save_game())
			
			queue_redraw()
			break


func _draw() -> void:
	if required_upgrade and required_arrow_goal != Vector2.ZERO:
		
		var end_point: Vector2 = $local_node.to_local(required_arrow_goal) + size / 2 
		var start_point: Vector2 = size / 2 
		
		var dir: Vector2 = start_point.direction_to(end_point)
		
		start_point += dir * size.x/2.2
		end_point -= dir * size.x/3
		
		var col: Color = Color(Color.BLACK,0.75)
		
		draw_line(start_point, end_point, col, 4.0)
		draw_circle(start_point,8.0,col)

###

func _on_mouse_entered() -> void:
	draw_required_arrow()
	if hint_panel:
		hint_panel.show()

func _on_mouse_exited() -> void:
	if hint_panel:
		hint_panel.hide()
