extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.set_ball_counter.connect(set_nr)
	
	set_nr(SaveManager.save_game.ball_amount)

func set_nr(new_nr: int):
	text = str(new_nr)
