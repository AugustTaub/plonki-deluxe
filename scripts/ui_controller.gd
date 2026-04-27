extends Control

var workshop_enabled: bool = false

@export var workshop_screen_node: Control

var hidden_workshop_pos: Vector2 = Vector2(0,2000)

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.workshop_toggled.connect(on_workshop_toggled)
	
	if workshop_screen_node:
		hidden_workshop_pos = workshop_screen_node.global_position

# Called every frame. 'delta' is the elapsed time since the previous frame.
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
