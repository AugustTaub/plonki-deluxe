extends HSlider

const CONFIG_PATH := "user://settings.cfg"
const BUS_NAME := "Master"

var bus_index: int

@export var volume_label: RichTextLabel

func _ready() -> void:
	bus_index = AudioServer.get_bus_index(BUS_NAME)
	load_volume()

func _on_h_slider_value_changed(slider_value: float) -> void:
	set_bus_volume(slider_value)
	save_volume(slider_value)

func set_bus_volume(slider_value: float) -> void:
	volume_label.text = "Volume(" + str(int(slider_value)) + "%):"
	
	if slider_value <= 0.0:
		AudioServer.set_bus_volume_db(bus_index, -80.0) # Mute
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		
		var db = linear_to_db(slider_value / 100.0)
		AudioServer.set_bus_volume_db(bus_index, db)

func save_volume(slider_value: float) -> void:
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", slider_value)
	config.save(CONFIG_PATH)

func load_volume() -> void:
	var config = ConfigFile.new()
	var err = config.load(CONFIG_PATH)
	
	if err == OK:
		
		var saved_value = config.get_value("audio", "master_volume", 100.0)
		value = saved_value
		set_bus_volume(saved_value)
	else:
		
		value = 100.0
		set_bus_volume(100.0)
