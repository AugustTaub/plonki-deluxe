extends Node2D

class_name CoinGetNrManager

var mesh_instance_nr: int = 1000
var active_coin_nrs: Array[CoinNrData] = []

@export var nr_life_time: float = 0.6
@export var nr_spread: float = 16.0

class CoinNrData extends RefCounted:
	var mesh_i: int = -1
	var is_active: bool = false
	var pos: Vector2 = Vector2.ZERO
	var size: float = 1.0
	var coin_amount: int = 1
	
	var curr_life_time: float = 0.0

@export var coin_multimesh: MultiMeshInstance2D

func _ready() -> void:
	
	SignalBus.spawn_coin_get_nr.connect(create_coin_nr)
	
	coin_multimesh.multimesh.instance_count = mesh_instance_nr
	
	for i in range(mesh_instance_nr):
		var new_data = CoinNrData.new()
		new_data.mesh_i = i
		active_coin_nrs.append(new_data)
		coin_multimesh.multimesh.set_instance_transform_2d(i, Transform2D(0, Vector2.ZERO, 0, Vector2.ZERO))
	

func create_coin_nr(amount: int = 1, pos: Vector2 = Vector2.ZERO, size: float = 1.0):
	for coin in active_coin_nrs:
		if not coin.is_active:
			coin.is_active= true
			coin.pos= pos + Vector2(randf_range(-nr_spread,nr_spread) , randf_range(-nr_spread,nr_spread))
			coin.size = 1.0
			coin.coin_amount = amount
			coin.curr_life_time = 0.0
			return

func _process(delta: float) -> void:
	for coin in active_coin_nrs:
		if not coin.is_active:
			continue
		
		coin.curr_life_time += delta
		var progress = coin.curr_life_time / nr_life_time + 0.5
		
		if coin.curr_life_time >= nr_life_time:
			var cdata = Color(coin.coin_amount, 0.0, 0, 0) 
			coin_multimesh.multimesh.set_instance_custom_data(coin.mesh_i, cdata) #make it transparent so it dissapears instantly
			coin_multimesh.multimesh.set_instance_transform_2d(coin.mesh_i, Transform2D(0, Vector2.ZERO, 0, Vector2.ZERO))
			coin.is_active = false
			continue
		
		var y_scale_modifier: float = 1.0
		
		if coin.curr_life_time >= nr_life_time * 0.666:
			y_scale_modifier = 1 - ((coin.curr_life_time - (nr_life_time * 0.666)) / (nr_life_time * 0.333))
		
		var current_scale = clamp(progress,0.5,1.0)
		
		var xform = Transform2D(0, Vector2(current_scale, -current_scale*y_scale_modifier), 0, coin.pos + Vector2(0,-progress*22))
		coin_multimesh.multimesh.set_instance_transform_2d(coin.mesh_i, xform)
		
		var s_data = Color(coin.coin_amount, 1.0, 0, 0) 
		coin_multimesh.multimesh.set_instance_custom_data(coin.mesh_i, s_data)
