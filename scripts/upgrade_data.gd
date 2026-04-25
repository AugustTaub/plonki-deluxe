extends Resource
class_name UpgradeData

@export var name: String = "default"
@export var start_price: int = 100
@export var max_level: int = 3
@export var scaling_curve: Curve = preload("res://2D/curves/standard.tres")
