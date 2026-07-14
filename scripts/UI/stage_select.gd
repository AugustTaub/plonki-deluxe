extends PanelContainer

var preloaded_stage_button = preload("res://scenes/UI/stage_select_button.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.broadcast_available_stages.connect(gen_buttons)

func gen_buttons(stages: Array[StageNode]):
	for stage: StageNode in stages:
		var instance: StageSelectButton = preloaded_stage_button.instantiate()
		$HBoxContainer.add_child(instance)
		instance.text = stage.name
		instance.associated_stage = stage
