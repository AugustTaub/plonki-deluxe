extends Node

var curr_cs: float = 0.0
var ten_sec_cs: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.coins_increased.connect(_on_coins_increased)

#func _process(_delta):
	#print(ten_sec_cs/10)


func _on_coins_increased(amount: int):
	ten_sec_cs += amount
	curr_cs = ten_sec_cs/10
	get_tree().create_timer(10.0).timeout.connect(func(): ten_sec_cs -= amount)
