extends RichTextLabel


# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.set_debug_txt.connect(set_txt)


func set_txt(txt: String):
	text = txt
