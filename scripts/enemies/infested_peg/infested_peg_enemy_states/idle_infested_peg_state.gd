class_name IdleInfestedPegState
extends InfestedPegState


func _init() -> void:
	color = Color.WHEAT

func enter(actor: InfestedPegManager.PegData) -> void:
	
	peg_manager_node.change_peg_state(actor,"walking")

@warning_ignore("unused_parameter")
func exit(actor: InfestedPegManager.PegData) -> void:
	pass

@warning_ignore("unused_parameter")
func physics_process(_delta: float, actor: InfestedPegManager.PegData) -> void:
	peg_manager_node.change_peg_state(actor,"walking")
