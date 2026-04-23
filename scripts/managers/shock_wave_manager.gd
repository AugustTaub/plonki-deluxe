extends Node2D

var mesh_instance_nr: int = 1000
var active_waves: Array[WaveData] = []

class WaveData extends RefCounted:
	var mesh_i: int = -1
	var is_active: bool = false
	var max_radius: float = 64.0
	var curr_life_time: float = 0.0
	var max_life_time: float = 1.0
	var pos: Vector2 = Vector2.ZERO

@export var wave_multimesh: MultiMeshInstance2D

func _ready() -> void:
	
	SignalBus.spawn_shock_wave.connect(create_wave)
	
	wave_multimesh.multimesh.instance_count = mesh_instance_nr
	
	for i in range(mesh_instance_nr):
		var w = WaveData.new()
		w.mesh_i = i
		active_waves.append(w)
		wave_multimesh.multimesh.set_instance_transform_2d(i, Transform2D(0, Vector2.ZERO, 0, Vector2.ZERO))

func create_wave(wave_pos: Vector2, wave_radius: float = 32.0,wave_life_time: float = 1):
	for wave in active_waves:
		if not wave.is_active:
			wave.is_active = true
			wave.max_life_time = wave_life_time
			wave.pos = wave_pos
			wave.max_radius = wave_radius
			wave.curr_life_time = 0.0
			return

func _process(delta: float) -> void:
	
	for wave in active_waves:
		if not wave.is_active:
			continue
			
		wave.curr_life_time += delta
		var progress = wave.curr_life_time / wave.max_life_time
		
		if progress >= 1.0:
			wave.is_active = false
			wave_multimesh.multimesh.set_instance_transform_2d(wave.mesh_i, Transform2D(0, Vector2.ZERO, 0, Vector2.ZERO))
			continue
		
		
		var current_scale = (wave.max_radius * progress)
		
		var xform = Transform2D(0, Vector2(current_scale, current_scale), 0, wave.pos)
		wave_multimesh.multimesh.set_instance_transform_2d(wave.mesh_i, xform)
		
		var s_data = Color(progress, 0, 0, 0) 
		wave_multimesh.multimesh.set_instance_custom_data(wave.mesh_i, s_data)
