extends Node2D
class_name InfestedPegManager

@export var max_number_of_pegs: int = 1000
var simulate_time: float = 0.6
@export var state_script_arr: Array[Script] = []
var state_dict: Dictionary = {} 

# RID Area vars
var shared_shape_rid: RID
var pooled_areas: Dictionary = {} # ID -> RID
var rid_to_area_id: Dictionary = {}    # RID -> ID 

# RID Nav Agent Vars
var pooled_agents: Dictionary = {} # ID -> RID
var rid_to_agent_id: Dictionary = {}    # RID -> ID 

### EXPORT VARS
@export var adjustable_peg_multimesh: MultiMeshInstance2D

### DATA STRUCTURE
class PegData extends RefCounted:
	var health: int = 1
	
	var active: bool = true
	var pos: Vector2 = Vector2.ZERO
	var vel: Vector2 = Vector2.ZERO
	var instance_id: int = -1 
	var vis_scale: float = 1.0
	var state_name: String = ""
	
	var life_time: float = 0.0
	var peg_timer: float = 0.0
	var saved_time: float = 0.0
	var danger_dir: Vector2 = Vector2.ZERO
	
	var safe_velocity: Vector2 = Vector2.ZERO
	var agent_desired_velocity: Vector2 = Vector2.ZERO

###
var active_pegs: Array[PegData] = []
var delta_timer: float = 0

### THREADING CACHED VARS
var current_delta: float = 0.0
var current_frame: int = 0
var run_time: float = 0.0

### DEBUG
var peg_nr_spawned: int = 0

func _ready():
	SignalBus.spawn_infested_peg.connect(spawn_infested_peg) 
	
	# set up multimesh
	adjustable_peg_multimesh.multimesh.instance_count = max_number_of_pegs
	for i in range(max_number_of_pegs):
		adjustable_peg_multimesh.multimesh.set_instance_transform_2d(i, Transform2D(0, Vector2.ZERO, 0, Vector2.ZERO))
	
	# fill state dict
	var state_parent_node: Node2D = get_node("states")
	if state_parent_node:
		for state_node in state_parent_node.get_children():
			state_node.peg_manager_node = self
			state_node.nav_map = get_world_2d().navigation_map
			if state_node:
				var key = state_node.name
				add_state_to_dict(key, state_node)
	
	# create circle shape for coll
	shared_shape_rid = PhysicsServer2D.circle_shape_create()
	PhysicsServer2D.shape_set_data(shared_shape_rid, 16.0)
	
	# fill area pool
	for i in range(max_number_of_pegs):
		var new_area = create_internal_area()
		pooled_areas[i] = new_area
		rid_to_area_id[new_area] = i
	
	# fill agent pool
	for i in range(max_number_of_pegs):
		var agent_rid = NavigationServer2D.agent_create()
		
		var nav_map: RID = get_world_2d().navigation_map
		NavigationServer2D.agent_set_map(agent_rid, nav_map)
		
		NavigationServer2D.agent_set_avoidance_enabled(agent_rid, true)
		
		NavigationServer2D.agent_set_radius(agent_rid, 10.0)
		
		NavigationServer2D.agent_set_max_speed(agent_rid, 1000.0) 
		
		NavigationServer2D.agent_set_max_neighbors(agent_rid,3)
		
		NavigationServer2D.agent_set_avoidance_callback(
			agent_rid, 
			Callable(self, "_on_velocity_computed").bind(agent_rid) 
		)
		
		pooled_agents[i] = agent_rid
		rid_to_agent_id[agent_rid] = i

### COLL AREA 
func create_internal_area() -> RID:
	var area_rid = PhysicsServer2D.area_create()
	PhysicsServer2D.area_add_shape(area_rid, shared_shape_rid)
	PhysicsServer2D.area_set_collision_layer(area_rid, 1)
	PhysicsServer2D.area_set_monitorable(area_rid, true)
	return area_rid

func activate_area(id: int, pos: Vector2):
	if id <= pooled_areas.size() -1:
		
		var area_RID = pooled_areas[id]
		PhysicsServer2D.area_set_space(area_RID, get_world_2d().space)
		var area_transform = Transform2D(0, pos)
		PhysicsServer2D.area_set_transform(area_RID, area_transform)
	else:
		push_warning("InfestedPegManager: Tried to activate an area outside the area pool size!")

func deactivate_area(id: int):
	var area_RID = pooled_areas[id]
	PhysicsServer2D.area_set_space(area_RID, RID())

func get_peg_area_id_from_rid(hit_rid: RID) -> String:
	return str(rid_to_area_id.get(hit_rid, ""))

### AGENT

func _on_velocity_computed(safe_velocity: Vector2, agent_rid: RID):
	var id: int = get_agent_id_from_rid(agent_rid)
	if id >= 0 and id < active_pegs.size():
		active_pegs[id].safe_velocity = safe_velocity


func get_agent_id_from_rid(hit_rid: RID) -> int:
	return rid_to_agent_id.get(hit_rid, -1)


### STATE MACHINE

func add_state_to_dict(state_name: String, state_instance: InfestedPegState):
	state_dict[state_name] = state_instance

func change_peg_state(peg: PegData, new_state_name: String):
	call_deferred("_perform_change_peg_state", peg, new_state_name)

func _perform_change_peg_state(peg: PegData, new_state_name: String):
	if not state_dict.has(new_state_name): 
		push_warning("InfestedPegManager: Tried to enter unknown state: " + new_state_name )
		return
	
	if peg.state_name == new_state_name: 
		return
	
	if state_dict.has(peg.state_name):
		var old_state: InfestedPegState = state_dict[peg.state_name]
		old_state.exit(peg)
	
	var new_state: InfestedPegState = state_dict[new_state_name]
	new_state.enter(peg)
	peg.state_name = new_state_name

### PEG LOGIC

func spawn_infested_peg(spawn_pos: Vector2):
	#revive pegs if possible
	for peg in active_pegs:
		if not peg.active:
			peg.health = 1
			
			peg.active = true
			peg.pos = spawn_pos
			peg.state_name = "idle"
			peg.peg_timer = 0.0
			peg.life_time = 0.0
			peg.vel = Vector2.ZERO
			peg.agent_desired_velocity = Vector2.ZERO
			peg.safe_velocity = Vector2.ZERO
			peg.saved_time = 0.0
			
			activate_area(peg.instance_id, peg.pos)
			change_peg_state(peg, "idle")
			return
	
	# dont make make pegs if there are too many
	if active_pegs.size()+1 > max_number_of_pegs:
		return
	
	# create whole new peg
	var new_peg = PegData.new()
	new_peg.pos = spawn_pos
	new_peg.instance_id = active_pegs.size()
	activate_area(new_peg.instance_id, new_peg.pos)
	change_peg_state(new_peg, "idle")
	active_pegs.append(new_peg)

func _physics_process(delta):
	### DEBUG
	if Input.is_action_pressed("ui_accept"):
		spawn_infested_peg(Vector2(555,444)+ Vector2.UP.rotated(randf_range(0,2*PI))*100)
		peg_nr_spawned += 1
		print(peg_nr_spawned)
	
	# cache parameters for worker threads
	current_delta = delta
	current_frame = Engine.get_frames_drawn()
	run_time += delta
	
	# add tasks for multithreading
	if active_pegs.size() > 0:
		var task_id = WorkerThreadPool.add_group_task(_process_peg_batch, active_pegs.size())
		WorkerThreadPool.wait_for_group_task_completion(task_id)
	
	# visuals on main thread
	for peg in active_pegs:
		update_peg_visuals(peg)

func _process_peg_batch(index: int):
	var peg = active_pegs[index]
	if not peg.active:
		return
	
	peg.life_time += current_delta
	peg.peg_timer += current_delta 
	
	# run logic every 0.2 seconds
	if peg.peg_timer >= 0.2:
		peg.peg_timer -= 0.2 
	
	if state_dict.has(peg.state_name):
		state_dict[peg.state_name].current_run_time = run_time
		state_dict[peg.state_name].physics_process(current_delta, peg)
	
		# update collision area pos
		var id: int = peg.instance_id
		if pooled_areas.has(id):
			var area_rid = pooled_areas[id]
			var area_transform = Transform2D(0, peg.pos)
			PhysicsServer2D.area_set_transform(area_rid, area_transform)
	
	# movement
	peg.vel = peg.safe_velocity
	peg.pos += peg.vel * current_delta

func update_peg_visuals(peg: PegData):
	if adjustable_peg_multimesh and peg.instance_id >= 0 and peg.instance_id <= active_pegs.size()-1:
		var multmesh_i: int = peg.instance_id
		
		if not peg.active:
			adjustable_peg_multimesh.multimesh.set_instance_transform_2d(multmesh_i, Transform2D(0, Vector2.ZERO, 0, Vector2.ZERO))
			return 
		
		var trans = Transform2D(0, peg.vis_scale * Vector2.ONE, 0, peg.pos)
		adjustable_peg_multimesh.multimesh.set_instance_transform_2d(multmesh_i, trans)
		
		#set state color
		if state_dict.has(peg.state_name):
			adjustable_peg_multimesh.multimesh.set_instance_color(multmesh_i, state_dict[peg.state_name].color)

func take_damage(peg: PegData, damage_amount: int):
	peg.health -= damage_amount
	if peg.health <= 0:
		die(peg)

func die(peg: PegData):
	peg.active = false
	deactivate_area(peg.instance_id)

###

func _exit_tree():
	for id in pooled_areas:
		PhysicsServer2D.free_rid(pooled_areas[id])
	
	if shared_shape_rid.is_valid():
		PhysicsServer2D.free_rid(shared_shape_rid)
	
	for id in pooled_agents:
		var agent_rid = pooled_agents[id]
		if agent_rid.is_valid():
			NavigationServer2D.free_rid(agent_rid)
