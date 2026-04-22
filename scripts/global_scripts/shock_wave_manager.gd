extends Node2D

var mesh_instance_nr: int = 500

###

var active_waves: Array[WaveData] = []

### DATA CLASS
class WaveData extends RefCounted:
	var mesh_i: int = 0
	var is_active: bool = true
	var max_radius: float = 64
	var curr_radius: float = 0
	var max_life_time: float = 1
	var curr_life_time: float = 0
	var progress: float = 0
	var pos: Vector2 = Vector2.ZERO

### EXPORT MESHINSTANCE

@export var wave_multimesh: MultiMeshInstance2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	wave_multimesh.multimesh.instance_count = mesh_instance_nr
	for i in range(mesh_instance_nr):
		wave_multimesh.multimesh.set_instance_transform_2d(i, Transform2D(0, Vector2.ZERO, 0, Vector2.ZERO))
	

func create_wave(wave_pos: Vector2 = Vector2.ZERO, wave_radius: float = 64):
	
	
	for wave in active_waves:
		if not wave.is_active:
			wave.is_active = true
			wave.pos = wave_pos
			wave.max_radius = wave_radius
			wave.mesh_i = active_waves.size()
			
			return
	
	var new_wave = WaveData.new()
	
	new_wave.pos = wave_pos
	new_wave.max_radius = wave_radius
	
	if active_waves.size() > mesh_instance_nr:
		return
	
	new_wave.mesh_i = active_waves.size()
	
	
	active_waves.append(new_wave)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	create_wave(get_global_mouse_position())
	
	for wave in active_waves:
		if wave.curr_life_time >= wave.max_life_time:
			wave.is_active = false
		
		if  wave.is_active:
			wave_multimesh.multimesh.set_instance_transform_2d(wave.mesh_i, Transform2D(0, Vector2.ZERO, 0, Vector2.ZERO))
			return 
		
		wave.curr_life_time += delta
		wave.progress = wave.curr_life_time/ wave.max_life_time
		wave.curr_radius = wave.max_radius * wave.progress
		
		
		var s_data = Color(wave.curr_radius,0,0)
		wave_multimesh.multimesh.set_instance_custom_data(wave.mesh_i, s_data)
		
		var s_trans = Transform2D(0,wave.pos)
		wave_multimesh.multimesh.set_instance_transform_2d(wave.mesh_i, s_trans)
		
