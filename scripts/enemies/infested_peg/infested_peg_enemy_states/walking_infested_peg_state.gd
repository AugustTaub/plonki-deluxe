class_name WalkingInfestedPegState
extends InfestedPegState

var screen_size: Vector2

func _init() -> void:
	color = Color.BLUE


@warning_ignore("unused_parameter")
func enter(actor: InfestedPegManager.PegData) -> void:
	screen_size = peg_manager_node.get_viewport_rect().size


func exit(actor: InfestedPegManager.PegData) -> void:
	actor.agent_desired_velocity = Vector2.ZERO

func physics_process(delta: float, actor: InfestedPegManager.PegData) -> void:
	var agent_rid: RID = peg_manager_node.pooled_agents[actor.instance_id]
	
	
	
	var close_enough: bool = actor.pos.distance_to(actor.goal_peg_pos) <= 10
	var peg_is_alive: bool = actor.goal_peg.curr_peg_state != DestructiblePeg.peg_state.REANIMATING
	
	# eat peg if possible
	if not actor.has_eaten and close_enough and peg_is_alive:
		actor.goal_peg.destroy_without_payout.call_deferred()
		actor.curr_value += actor.goal_peg.value * 24 
		actor.fear *= 0.1
		actor.has_eaten = true
		actor.vis_scale = 1.3
		
		SignalBus.play_sound.emit.call_deferred("eat", 1.5)
	
	
	# decrease fear
	if not actor.has_eaten:
		actor.fear = clamp(actor.fear - delta*30 ,0,100)
	
	var goal_pos: Vector2
	if actor.has_eaten:
		# if not hungry anymore go back to top of screen
		goal_pos = Vector2(0, -1600)
		
	else:
		# if hungry go to the goal peg and try to eat it
		goal_pos = actor.goal_peg_pos
	
	
	# ask the server for a path from current pos to goal
	var path: PackedVector2Array = NavigationServer2D.map_get_path(
		nav_map, 
		actor.pos, 
		goal_pos, 
		true
	)
	
	var move_speed: float = 50.0 + actor.fear
	
	if actor.has_eaten:
		move_speed += actor.fear * 0.3
	
	
	if path.size() > 1:
		var next_path_pos: Vector2 = path[1]
		var direction: Vector2 = actor.pos.direction_to(next_path_pos)
		actor.agent_desired_velocity = direction * move_speed
	else:
		actor.agent_desired_velocity = Vector2.ZERO
	
	
	# avoidance sync position ,velocity 
	NavigationServer2D.agent_set_position(agent_rid, actor.pos)
	NavigationServer2D.agent_set_velocity(agent_rid, actor.agent_desired_velocity)
