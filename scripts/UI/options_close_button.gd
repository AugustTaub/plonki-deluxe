extends Button



func _on_pressed():
	SignalBus.options_toggled.emit()
