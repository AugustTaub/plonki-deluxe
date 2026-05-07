extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.set_money_counter.connect(set_money)

func set_money(new_amount: int):
	$money.text = amount_to_string(new_amount)
	


func amount_to_string(money_amount: int):
	pass
	#var size_degree: int = log()
	
	
	
	#var low_float: float = (float(money_amount))/100
	#
	#if money_amount < 10000:
		#
		#return str(low_float)
		#
	#elif money_amount < 1000000:
		#return str((round(low_float/10)/100)) + " K"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
