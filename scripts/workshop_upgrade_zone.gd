extends Control

class_name WorkshopUpgradeZone

var is_unlocked: bool = false # this should be replaced with a call to the save state manager
var is_hovered: bool = false

enum vis_state{LOCKED,LOCKED_HOVERED,UNLOCKED,UNLOCKED_HOVERED}
var curr_vis_state: vis_state = vis_state.LOCKED

@export var sprite: TextureRect
@export var button_parent: Control
@export var coll_area: Area2D
@export var unlock_cost_text: RichTextLabel

@export var associated_upgrade: UpgradeData

@onready var buttons: Array = button_parent.get_children()

# Called when the node enters the scene tree for the first time.
func _ready():
	coll_area.mouse_entered.connect(on_mouse_entered)
	coll_area.mouse_exited.connect(on_mouse_exited)
	
	if SaveManager.save_game.unlocked_upgrades.has(associated_upgrade):
		change_vis_state(vis_state.UNLOCKED)
	else:
		change_vis_state(vis_state.LOCKED)
	
	
	if unlock_cost_text and associated_upgrade:
		unlock_cost_text.text = "Unlock: " + str(associated_upgrade.start_price)

func _process(delta):
	match curr_vis_state:
		vis_state.LOCKED:
			if is_hovered:
				change_vis_state(vis_state.LOCKED_HOVERED)
			
			
		vis_state.LOCKED_HOVERED:
			if not is_hovered:
				change_vis_state(vis_state.LOCKED)
			
			if Input.is_action_just_pressed("fire_ball") and associated_upgrade:
				if SaveManager.save_game.money_amount >= associated_upgrade.start_price:
					SaveManager.set_money(SaveManager.save_game.money_amount-associated_upgrade.start_price)
					SaveManager.add_upgrade(associated_upgrade)
					change_vis_state(vis_state.UNLOCKED)
				
		vis_state.UNLOCKED:
			if is_hovered:
				change_vis_state(vis_state.UNLOCKED_HOVERED)
			
			
		vis_state.UNLOCKED_HOVERED:
			if not is_hovered:
				change_vis_state(vis_state.UNLOCKED)
			




func change_vis_state(new_state: vis_state):
	exit_vis_state(curr_vis_state)
	enter_vis_state(new_state)
	
	curr_vis_state = new_state

func exit_vis_state(exit_state: vis_state):
	match exit_state:
		vis_state.LOCKED:
			pass
		vis_state.LOCKED_HOVERED:
			pass
		vis_state.UNLOCKED:
			pass
		vis_state.UNLOCKED_HOVERED:
			sprite.scale = Vector2.ONE

func enter_vis_state(enter_state: vis_state):
	match enter_state:
		vis_state.LOCKED:
			modulate = Color.DARK_SLATE_GRAY
			
			for button in $upgrade_buttons.get_children():
				if button is WorkshopUpgradeButton:
					button.set_button_disabled(true)
			
			
		vis_state.LOCKED_HOVERED:
			modulate = Color.DIM_GRAY
		vis_state.UNLOCKED:
			modulate = Color.WHITE
			unlock_cost_text.hide()
			
			for button in $upgrade_buttons.get_children():
				if button is WorkshopUpgradeButton:
					button.set_button_disabled(false)
			
		vis_state.UNLOCKED_HOVERED:
			sprite.scale = Vector2.ONE * 1.1

func on_mouse_entered():
	is_hovered = true

func on_mouse_exited():
	is_hovered = false
