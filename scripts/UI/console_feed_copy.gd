extends TextEdit

func _ready() -> void:
	editable = false
	context_menu_enabled = true # Keeps right-click menu active

# Intercept input to handle copying manually if standard copy fails
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_copy") and has_focus():
		var selected_text = get_selected_text()
		if selected_text != "":
			DisplayServer.clipboard_set(selected_text)
