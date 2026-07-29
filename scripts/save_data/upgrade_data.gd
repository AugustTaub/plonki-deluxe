extends Resource
class_name UpgradeData

@export_category("general")
@export var name: String = "default"
@export var pretty_name: String = "Default"
@export var unit: String = ""
@export var max_level: int = 3


@export_category("price")
@export var start_price: int = 100
@export var end_price: int = 1000
@export var price_scaling_curve: Curve = preload("res://2D/curves/standard.tres")

@export_category("result")
@export var start_result: float = 100
@export var end_result: float = 1000
@export var result_scaling_curve: Curve = preload("res://2D/curves/standard.tres")
@export var wants_integer_result: bool = false

func get_level_price(level: int) -> int:
	var result = start_price
	
	result = start_price + end_price * price_scaling_curve.sample(level/float(max_level))
	
	return result

func get_level_result(level: int) -> float:
	var result = start_result
	
	var total_dist = end_result - start_result
	
	result = start_result + total_dist * result_scaling_curve.sample(level/float(max_level))
	
	if wants_integer_result:
		result = snapped(result,1.0)
	
	return result
