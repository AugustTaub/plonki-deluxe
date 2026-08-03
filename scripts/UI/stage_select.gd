extends PanelContainer

var preloaded_stage_button = preload("res://scenes/UI/stage_select_button.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.broadcast_available_stages.connect(gen_buttons)
	
	SaveManager.save_game_changed.connect(update_button_locks)
	
	await SignalBus.broadcast_available_stages
	update_button_locks()

func gen_buttons(stages: Array[StageNode]):
	for stage: StageNode in stages:
		var instance: StageSelectButton = preloaded_stage_button.instantiate()
		$HBoxContainer.add_child(instance)
		instance.text = stage.name
		instance.associated_stage = stage

func update_button_locks():
	
	for child in $HBoxContainer.get_children():
		if child is StageSelectButton:
			var stage: StageNode = child.associated_stage
			
			if stage.unlock_upgrade:
				if SaveManager.save_game.unlocked_upgrades.has(stage.unlock_upgrade):
					child.disabled = false
				else:
					child.disabled = true
