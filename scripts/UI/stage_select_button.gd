extends Button

class_name StageSelectButton

var associated_stage: StageNode


func _on_pressed():
	if associated_stage != null:
		SignalBus.play_sound.emit("click")
		
		SignalBus.select_stage.emit(associated_stage)
