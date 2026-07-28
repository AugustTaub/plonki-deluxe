class_name DyingInfestedPegState
extends InfestedPegState


func _init() -> void:
	color = Color.BLACK

@warning_ignore("unused_parameter")
func enter(actor: InfestedPegManager.PegData) -> void:
	actor.vel = Vector2.ZERO

@warning_ignore("unused_parameter")
func exit(actor: InfestedPegManager.PegData) -> void:
	pass

@warning_ignore("unused_parameter")
func physics_process(delta: float, actor: InfestedPegManager.PegData) -> void:
	actor.vis_scale -= delta * 2
	if actor.vis_scale <= 0:
		actor.active = false
