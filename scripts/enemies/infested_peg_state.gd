extends Resource

class_name InfestedPegState

@export var color: Color = Color.WHITE

var peg_manager_node: InfestedPegManager

func enter(actor: InfestedPegManager.PegData) -> void:
	pass

func exit(actor: InfestedPegManager.PegData) -> void:
	pass

func physics_process(_delta: float, actor: InfestedPegManager.PegData) -> void:
	pass
