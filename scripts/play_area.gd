extends ReferenceRect

var has_mouse: bool = false

func _ready():
	pass

func _on_mouse_entered():
	has_mouse = true


func _on_mouse_exited():
	has_mouse = false
