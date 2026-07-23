class_name DodgingInfestedPegState
extends InfestedPegState

var dodge_time: float = 0.5

func _init() -> void:
	color = Color.GREEN_YELLOW

func enter(actor: InfestedPegManager.PegData) -> void:
	actor.saved_time = actor.peg_timer
	
	var move_speed: float = 1500.0 
	actor.agent_desired_velocity = actor.danger_dir * move_speed

func exit(actor: InfestedPegManager.PegData) -> void:
	actor.agent_desired_velocity = Vector2.ZERO

func physics_process(_delta: float, actor: InfestedPegManager.PegData) -> void:
	var agent_rid: RID = peg_manager_node.pooled_agents[actor.instance_id]
	
	NavigationServer2D.agent_set_position(agent_rid, actor.pos)
	
	NavigationServer2D.agent_set_velocity(agent_rid, actor.agent_desired_velocity)
	
	if abs(actor.saved_time-actor.peg_timer) >= dodge_time:
		peg_manager_node.change_peg_state(actor,"walking")
