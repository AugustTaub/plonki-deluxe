extends Button

var reset_aborted: bool = false
var button_is_down: bool = false
var time_since_button_down: float = 0.0


var gradient_tex: GradientTexture1D = preload("res://2D/godot_gen_textures/hold_reset_gradient_tex.tres")

@export var notification_label: RichTextLabel

func _ready():
	gradient_tex.gradient.set_offset(1,0.01)

func _process(delta):
	if button_is_down:
		time_since_button_down += delta 
		gradient_tex.gradient.set_offset(1,time_since_button_down/3)
		
		if time_since_button_down >= 3.0:
			time_since_button_down = 0.0
			SaveManager.reset_save_game()
			if notification_label:
				notification_label.text = "All save data was deleted."
				await get_tree().create_timer(5.0).timeout
				notification_label.text = ""



func _on_button_down():
	button_is_down = true
	gradient_tex.gradient.set_offset(1,0.01)


func _on_button_up():
	button_is_down = false
	gradient_tex.gradient.set_offset(1,0.01)
	time_since_button_down = 0.0
