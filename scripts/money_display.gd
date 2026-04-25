extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.set_money_counter.connect(set_money)

func set_money(new_amount: int):
	$money.text = str(new_amount)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
