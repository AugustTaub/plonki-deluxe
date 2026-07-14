extends ReferenceRect

var has_mouse: bool = false

func _on_mouse_entered():
	has_mouse = true
	GlobalVars.mouse_is_in_play_area = true

func _on_mouse_exited():
	has_mouse = false
	GlobalVars.mouse_is_in_play_area = false
