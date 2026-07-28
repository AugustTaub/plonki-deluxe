extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.set_money_counter.connect(set_money)

func set_money(new_amount: int):
	$money.text = amount_to_string(new_amount)
	$money.tooltip_text = str(new_amount) + "$"


func amount_to_string(money_amount: int):
	
	var nr_length: int = str(abs(money_amount)).length()
	
	var with_decimal: float = money_amount/ 100.0	
	
	var return_val: String = str(money_amount)
	
	#var size_degree: int = log()
	
	if nr_length <= 2:
		return_val = str(with_decimal)
	elif nr_length <= 4:
		return_val = str(with_decimal)
	elif nr_length <= 6:
		return_val = str(with_decimal)
	elif nr_length <= 8:
		return_val = str(snappedf(money_amount/100000.0,0.1)) + " K"
	elif nr_length <= 12:
		return_val = str(snappedf(money_amount/1000.0/1000.0/10.0, 0.1)) + " Mio."
	
	
	return return_val
	#var low_float: float = (float(money_amount))/100
	#
	#if money_amount < 10000:
		#
		#return str(low_float)
		#
	#elif money_amount < 1000000:
		#return str((round(low_float/10)/100)) + " K"


# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta):
	pass
