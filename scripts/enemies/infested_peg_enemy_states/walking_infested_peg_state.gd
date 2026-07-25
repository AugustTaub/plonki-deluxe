class_name WalkingInfestedPegState
extends InfestedPegState

var goal_pos: Vector2

func _init() -> void:
	color = Color.BLUE

func enter(actor: InfestedPegManager.PegData) -> void:
	actor.saved_time = actor.peg_timer
	
	var screen_size: Vector2 = peg_manager_node.get_viewport_rect().size
	goal_pos = Vector2(screen_size.x / 2.0, 0.0)

func exit(actor: InfestedPegManager.PegData) -> void:
	actor.agent_desired_velocity = Vector2.ZERO

func physics_process(_delta: float, actor: InfestedPegManager.PegData) -> void:
	var agent_rid: RID = peg_manager_node.pooled_agents[actor.instance_id]
	
	# ask the server for a path from current pos to goal
	var path: PackedVector2Array = NavigationServer2D.map_get_path(
		nav_map, 
		actor.pos, 
		goal_pos, 
		true
	)
	
	var move_speed: float = 50.0 
	
	if path.size() > 1:
		var next_path_pos: Vector2 = path[1]
		var direction: Vector2 = actor.pos.direction_to(next_path_pos)
		actor.agent_desired_velocity = direction * move_speed
	else:
		actor.agent_desired_velocity = Vector2.ZERO
		
	# avoidance sync position ,velocity 
	NavigationServer2D.agent_set_position(agent_rid, actor.pos)
	NavigationServer2D.agent_set_velocity(agent_rid, actor.agent_desired_velocity)
