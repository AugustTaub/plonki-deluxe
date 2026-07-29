extends Control

func _on_pressed():
	SignalBus.workshop_toggled.emit()
