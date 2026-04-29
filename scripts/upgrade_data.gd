extends Resource
class_name UpgradeData

@export var name: String = "default"
@export var start_price: int = 100
@export var end_price: int = 1000
@export var max_level: int = 3
@export var scaling_curve: Curve = preload("res://2D/curves/standard.tres")

func get_curr_price(level: int) -> int:
	var result = start_price
	
	result = start_price + end_price * scaling_curve.sample(level/float(max_level))
	
	return result
