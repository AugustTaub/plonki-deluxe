extends Control

var workshop_enabled: bool = false
var options_enabled: bool = false

@export var workshop_screen_node: Control
@export var options_node: Control

var hidden_workshop_pos: Vector2 = Vector2(0,2000)
var hidden_options_pos: Vector2 = Vector2(2000,0)

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.workshop_toggled.connect(on_workshop_toggled)
	SignalBus.options_toggled.connect(on_options_toggled)
	
	if workshop_screen_node:
		hidden_workshop_pos = workshop_screen_node.global_position

# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta):
	pass


func _on_workshop_button_pressed():
	SignalBus.workshop_toggled.emit()

func on_workshop_toggled():
	if not workshop_screen_node: return
	
	workshop_enabled = !workshop_enabled
	match workshop_enabled:
		true:
			var tween = create_tween()
			tween.tween_property(workshop_screen_node,"global_position",global_position,0.3)
			get_tree().paused = true
		false:
			var tween = create_tween()
			tween.tween_property(workshop_screen_node,"global_position",hidden_workshop_pos,0.3)
			get_tree().paused = false


func _on_options_button_pressed():
	SignalBus.options_toggled.emit()

func on_options_toggled():
	if not options_node: return
	
	options_enabled = !options_enabled
	match options_enabled:
		true:
			var tween = create_tween()
			
			var screen_size: Vector2 = get_viewport_rect().size
			
			tween.tween_property(options_node,"global_position",screen_size/2 - options_node.size/2,0.3)
			get_tree().paused = true
		false:
			var tween = create_tween()
			tween.tween_property(options_node,"global_position",hidden_options_pos,0.3)
			get_tree().paused = false
