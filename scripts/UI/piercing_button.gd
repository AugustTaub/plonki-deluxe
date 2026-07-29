extends Button


# Called when the node enters the scene tree for the first time.
func _ready():
	set_text_based_on_toggle()
	
	hide()
	
	SignalBus.enable_piercing_button.connect(show)

func _on_toggled(toggled_on):
	set_text_based_on_toggle()
	GlobalVars.piercing_enabled = toggled_on

func set_text_based_on_toggle():
	var toggled_on: bool = button_pressed
	if toggled_on:
		text = "Piercing: ON"
	else:
		text = "Piercing: OFF"
