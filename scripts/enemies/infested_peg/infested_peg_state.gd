extends Node2D

class_name InfestedPegState

@export var color: Color = Color.WHITE

var peg_manager_node: InfestedPegManager
var nav_map: RID
var current_run_time: float = 0

@warning_ignore("unused_parameter")
func enter(actor: InfestedPegManager.PegData) -> void:
	pass

@warning_ignore("unused_parameter")
func exit(actor: InfestedPegManager.PegData) -> void:
	pass

@warning_ignore("unused_parameter")
func physics_process(_delta: float, actor: InfestedPegManager.PegData) -> void:
	pass
