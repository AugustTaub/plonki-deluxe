extends Control

class_name WorkshopUpgradeZone

enum vis_state { LOCKED, LOCKED_HOVERED, UNLOCKED, UNLOCKED_HOVERED }
var curr_vis_state: vis_state = vis_state.LOCKED
var is_hovered: bool = false

@export var zone_name: String = "Zone"

@export var sprite: TextureRect
@export var button_parent: Control
@export var coll_area: Area2D
@export var unlock_cost_text: RichTextLabel

@export var associated_upgrade: UpgradeData

func _ready() -> void:
	SignalBus.options_toggled.connect(update_visuals)
	
	if coll_area:
		coll_area.mouse_entered.connect(on_mouse_entered)
		coll_area.mouse_exited.connect(on_mouse_exited)
	
	update_visuals()
	

func update_visuals():
	if is_zone_unlocked():
		change_vis_state(vis_state.UNLOCKED)
	else:
		change_vis_state(vis_state.LOCKED)



func is_zone_unlocked() -> bool:
	return associated_upgrade != null and SaveManager.save_game != null and SaveManager.save_game.unlocked_upgrades.has(associated_upgrade)

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	match curr_vis_state:
		vis_state.LOCKED:
			if is_hovered:
				change_vis_state(vis_state.LOCKED_HOVERED)
				
		vis_state.LOCKED_HOVERED:
			if not is_hovered:
				change_vis_state(vis_state.LOCKED)
			
			if Input.is_action_just_pressed("fire_ball") and associated_upgrade:
				if SaveManager.save_game.money_amount >= associated_upgrade.start_price:
					SaveManager.set_money(SaveManager.save_game.money_amount - associated_upgrade.start_price)
					SaveManager.add_upgrade(associated_upgrade)
					change_vis_state(vis_state.UNLOCKED)
				
		vis_state.UNLOCKED:
			if is_hovered:
				change_vis_state(vis_state.UNLOCKED_HOVERED)
				
		vis_state.UNLOCKED_HOVERED:
			if not is_hovered:
				change_vis_state(vis_state.UNLOCKED)

func change_vis_state(new_state: vis_state) -> void:
	exit_vis_state(curr_vis_state)
	enter_vis_state(new_state)
	
	if new_state == vis_state.UNLOCKED and curr_vis_state == vis_state.LOCKED_HOVERED:
		SignalBus.play_sound.emit("paid")
	
	curr_vis_state = new_state

func exit_vis_state(exit_state: vis_state) -> void:
	match exit_state:
		vis_state.UNLOCKED_HOVERED:
			if sprite:
				sprite.scale = Vector2.ONE

func enter_vis_state(enter_state: vis_state) -> void:
	match enter_state:
		vis_state.LOCKED:
			modulate = Color.DARK_SLATE_GRAY
			_set_buttons_disabled(true)
			if unlock_cost_text and associated_upgrade:
				unlock_cost_text.text = zone_name + " \n Buy for: " + str(associated_upgrade.start_price)
			
		vis_state.LOCKED_HOVERED:
			modulate = Color.DIM_GRAY
			
		vis_state.UNLOCKED:
			modulate = Color.WHITE
			if unlock_cost_text:
				unlock_cost_text.hide()
			_set_buttons_disabled(false)
			
			
			
		vis_state.UNLOCKED_HOVERED:
			if sprite:
				sprite.scale = Vector2.ONE * 1.1

func _set_buttons_disabled(disabled_flag: bool) -> void:
	var container: Node = button_parent if button_parent else get_node_or_null("upgrade_buttons")
	if container:
		for button in container.get_children():
			if button is WorkshopUpgradeButton:
				button.set_button_disabled(disabled_flag)

func on_mouse_entered() -> void:
	is_hovered = true

func on_mouse_exited() -> void:
	is_hovered = false
