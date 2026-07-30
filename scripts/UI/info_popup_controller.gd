extends Control

@export var win_screen: Control
@export var intro_screen: Control
@export var reward_plushy: Control

var win_x: Button
var intro_x: Button

# Called when the node enters the scene tree for the first time.
func _ready():
	if not win_screen or not intro_screen:
		push_warning("Info popup controller: win screen or intro screen missing!")
		return
	
	win_x = win_screen.get_node("x_button")
	intro_x = intro_screen.get_node("x_button")
	
	win_x.pressed.connect(win_screen.hide)
	intro_x.pressed.connect(intro_screen.hide)
	
	SignalBus.upgrades_complete.connect(_on_upgrades_complete)
	
	if SaveManager.check_if_save_is_empty():
		intro_screen.show()
		

func _on_upgrades_complete():
	win_screen.show()
	SignalBus.workshop_toggled.connect(reward_plushy.show)
