extends ReferenceRect

var has_mouse: bool = false

func _ready():
	GlobalVars.play_area_rect =Rect2(global_position,size)

func _on_mouse_entered():
	has_mouse = true
	GlobalVars.mouse_is_in_play_area = true


func _on_mouse_exited():
	has_mouse = false
	GlobalVars.mouse_is_in_play_area = false
