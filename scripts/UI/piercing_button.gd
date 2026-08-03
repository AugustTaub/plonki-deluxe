extends Button

@export var associated_upgrade: UpgradeData

var is_unlocked: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	set_text_based_on_toggle()
	hide()
	
	SignalBus.enable_piercing_button.connect(_on_enable_piercing_button)
	
	SaveManager.save_game_changed.connect(update_from_save)
	
	update_from_save()

func update_from_save():
	if not associated_upgrade: return
	
	is_unlocked = SaveManager.save_game.unlocked_upgrades.has(associated_upgrade)
	
	if is_unlocked and not visible:
		show()

func _on_enable_piercing_button():
	if is_unlocked:
		show()

func _on_toggled(toggled_on):
	set_text_based_on_toggle()
	GlobalVars.piercing_enabled = toggled_on

func set_text_based_on_toggle():
	var toggled_on: bool = button_pressed
	if toggled_on:
		text = "Piercing: ON"
	else:
		text = "Piercing: OFF"
