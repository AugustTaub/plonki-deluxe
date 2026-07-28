extends Control

@onready var bg_tex: TextureRect = %bg_tex
@onready var nr_label: RichTextLabel = %nr_label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.set_ball_counter.connect(set_nr)
	SignalBus.ball_just_generated.connect(ball_generated_anim)
	
	set_nr(SaveManager.save_game.ball_amount)
	
	bg_tex.pivot_offset_ratio = Vector2.ONE * 0.5

func set_nr(new_nr: int):
	nr_label.text = "+" + str(new_nr)

func ball_generated_anim():
	
	var tween = create_tween()
	var tween2 = create_tween()
	tween.tween_property(bg_tex,"scale",Vector2.ONE * 1.2,0.2)
	tween2.tween_property(bg_tex,"rotation",bg_tex.rotation + PI/2,0.2)
	
	tween.tween_property(bg_tex,"scale",Vector2.ONE,0.1)
