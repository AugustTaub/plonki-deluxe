extends Node2D
class_name SoundManager


var time_since_last_plonk: float = 0.0

var sound_dict: Dictionary[String,AudioStreamPlayer2D]

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.play_sound.connect(_on_play_sound)
	
	#fill sound dict
	for node in get_children():
		if node is AudioStreamPlayer2D:
			sound_dict[node.name] = node
	

func _process(delta):
	time_since_last_plonk += delta


func _on_play_sound(sound_name: String, volume_modifier: float = 1.0):
	
	if not sound_dict.has(sound_name):
		push_warning("SoundManager: Unknown Sound Name! ", sound_name)
		return
	
	var player: AudioStreamPlayer2D = sound_dict[sound_name]
	
	# special case for peg destruction so it pitches up when more is hit
	if sound_name == "plonk":
		player.pitch_scale = 1.0 + clamp((1-time_since_last_plonk)*0.5,0.0,1.0)
		time_since_last_plonk = 0.0
	
	player.volume_db = (volume_modifier * 16.0)-16.0
	
	player.play()
