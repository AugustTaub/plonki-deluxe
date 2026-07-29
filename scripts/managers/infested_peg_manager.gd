extends Node2D
class_name InfestedPegManager

#global settings
@export var max_number_of_pegs: int = 1000
@export var desired_max_number_of_pegs: int = 600
@export var death_explosion_radius: float = 250
# bounding box for active pegs 
@onready var peg_bounding_box = Rect2($enemy_bounding_area.global_position,$enemy_bounding_area.size)

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
@export var stage_manager: StageManager

var death_explo_shape: RID

var time_since_last_spawn: float = 0.0
var active_peg_amount: int = 0

### DATA STRUCTURE
class PegData extends RefCounted:
	var health: int = 1
	var curr_value: int = 1
	var has_eaten: bool = false
	var fear: float = 0.0 # 0-100
	
	var goal_peg: DestructiblePeg
	var goal_peg_pos: Vector2 = Vector2.ZERO
	
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

var upgrade_preloader: ResourcePreloader

func _on_upgrade_preloader_loaded(preloader: ResourcePreloader):
	upgrade_preloader = preloader

func _ready():
	SignalBus.spawn_infested_peg.connect(spawn_infested_peg)
	SignalBus.upgrade_preloader_loaded.connect(_on_upgrade_preloader_loaded)
	
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
	
	# make explo shape
	death_explo_shape = PhysicsServer2D.circle_shape_create()
	PhysicsServer2D.shape_set_data(death_explo_shape, death_explosion_radius)


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
	
	var curr_stage_node: StageNode = stage_manager.curr_stage_node
	if curr_stage_node.navigation_region == null : return
	
	active_peg_amount += 1
	
	
	var upgrade: UpgradeData = upgrade_preloader.get_resource("infested_peg_value")
	var level: int = SaveManager.get_upgrade_level_by_name("infested_peg_value")
	
	var upgraded_value: int = int(upgrade.get_level_result(level))
	
	
	#revive pegs if possible
	for peg in active_pegs:
		if not peg.active:
			peg.health = 1
			peg.has_eaten = false
			peg.fear = 0.0
			
			peg.curr_value = upgraded_value
			
			peg.goal_peg = get_random_goal_peg()
			peg.goal_peg_pos = peg.goal_peg.global_position
			
			peg.active = true
			peg.pos = spawn_pos
			peg.state_name = "idle"
			peg.peg_timer = 0.0
			peg.life_time = 0.0
			peg.vel = Vector2.ZERO
			peg.agent_desired_velocity = Vector2.ZERO
			peg.safe_velocity = Vector2.ZERO
			peg.saved_time = 0.0
			peg.vis_scale = 1.0
			
			activate_area(peg.instance_id, peg.pos)
			change_peg_state(peg, "idle")
			
			
			return
	
	# dont make make pegs if there are too many
	if active_pegs.size()+1 > max_number_of_pegs:
		return
	
	# create whole new peg
	var new_peg = PegData.new()
	
	new_peg.pos = spawn_pos
	
	new_peg.curr_value = upgraded_value
	
	new_peg.goal_peg = get_random_goal_peg()
	new_peg.goal_peg_pos = new_peg.goal_peg.global_position
	
	new_peg.instance_id = active_pegs.size()
	activate_area(new_peg.instance_id, new_peg.pos)
	change_peg_state(new_peg, "idle")
	active_pegs.append(new_peg)

func _physics_process(delta):
	## DEBUG
	#if Input.is_action_pressed("ui_accept"):
		#spawn_infested_peg(Vector2(randf_range(0,400),0))
		#peg_nr_spawned += 1
		##print(peg_nr_spawned)
	
	SignalBus.set_debug_txt.emit(str(active_peg_amount) + "\nEnemies")
	
	## spawn infested pegs
	
	var intervall_upgrade: UpgradeData = upgrade_preloader.get_resource("infested_spawn_time")
	var level: int = SaveManager.get_upgrade_level_by_name("infested_spawn_time")
	
	var spawn_time: float = intervall_upgrade.get_level_result(level)
	
	time_since_last_spawn += delta
	if time_since_last_spawn > spawn_time and active_peg_amount < desired_max_number_of_pegs:
		time_since_last_spawn = 0.0
		spawn_infested_peg(Vector2(randf_range(0,300),-100))
		spawn_infested_peg(Vector2(randf_range(900,1000),-100))
	
	
	
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
	if peg.state_name == "walking" or peg.state_name == "dodging":
		peg.vel = peg.safe_velocity
	
	peg.pos += peg.vel * current_delta
	
	# check if oob
	if not peg_bounding_box.has_point(peg.pos):
		call_deferred("despawn", peg)

func update_peg_visuals(peg: PegData):
	if adjustable_peg_multimesh and peg.instance_id >= 0 and peg.instance_id <= active_pegs.size()-1:
		var multmesh_i: int = peg.instance_id
		
		if not peg.active:
			adjustable_peg_multimesh.multimesh.set_instance_transform_2d(multmesh_i, Transform2D(0, Vector2.ZERO, 0, Vector2.ZERO))
			return 
		
		
		var trans = Transform2D(0, peg.vis_scale * Vector2.ONE, 0, peg.pos)
		adjustable_peg_multimesh.multimesh.set_instance_transform_2d(multmesh_i, trans)
	
		# set color
		var centi_fear: float = peg.fear/100.0
		var inverse_fear: float = 1-centi_fear
		
		var peg_color: Color = Color(inverse_fear/2, inverse_fear/2, centi_fear, 1.0)
		adjustable_peg_multimesh.multimesh.set_instance_color(multmesh_i, peg_color)
		
		# set custom data
		var noise_seed: float = float(multmesh_i)
		
		var eye_angle: float = 0.0 
		
		if peg.fear >= 50.0:
			eye_angle += 1.0
		if peg.has_eaten:
			eye_angle += 2.0
		
		# 0 - 0.9 = low fear, low food
		# 1 - 1.9 = high fear, low food
		# 2 - 2.9 = low fear, high food
		# 3 - 3.9 = high fear, high food 
		
		#overwrite for death
		if peg.state_name == "dying":
			eye_angle = 3.5
		
		
		var donut_mode: float = 0.0
		if peg.has_eaten: donut_mode = 1.0
		
		var custom_data: Color = Color(noise_seed, eye_angle, donut_mode, 0)
		adjustable_peg_multimesh.multimesh.set_instance_custom_data(multmesh_i, custom_data)

func take_damage(peg: PegData, damage_amount: int):
	# Prevent multi-hits triggering death multiple times on the same frame
	if not peg.active: 
		return 
	
	peg.health -= damage_amount
	if peg.health <= 0:
		call_deferred("die", peg)

func die(peg: PegData):
	
	SaveManager.change_money_with_vis_nr(peg.curr_value, peg.pos)
	deactivate_area(peg.instance_id)
	
	# explode and cause fear
	SignalBus.spawn_shock_wave.emit(peg.pos, death_explosion_radius, 0.3)
	
	
	var space_state = get_world_2d().direct_space_state
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape_rid = death_explo_shape 
	query.transform = Transform2D(0, peg.pos)
	query.collision_mask = 1
	query.collide_with_areas = true
	
	var results = space_state.intersect_shape(query)
	
	for hit in results:
		
		var found_rid: RID = hit["rid"]
		if rid_to_area_id.has(found_rid):
			var found_id = rid_to_area_id[found_rid]
			var hit_peg: InfestedPegManager.PegData = active_pegs[found_id]
			
			if not hit_peg.active or hit_peg == peg:
				continue
			
			change_fear(hit_peg, 35.0)
	
	if peg.has_eaten:
		SignalBus.play_sound.emit("plomp_low",0.8)
	else:
		SignalBus.play_sound.emit("plomp_high",0.8)
	
	change_peg_state(peg, "dying")

func despawn(peg: PegData):
	deactivate_area(peg.instance_id)
	peg.active = false
	active_peg_amount -= 1


func change_fear(peg: PegData, amount: float):
	peg.fear += amount
	peg.fear = clamp(peg.fear, 0.0, 100.0)

###

func get_random_goal_peg():
	
	if not stage_manager:
		push_warning("InfestedPegManager: No stage Manager node attached!")
		return 
	
	
	var peg_arr: Array[DestructiblePeg] = stage_manager.curr_stage_node.peg_nodes
	
	var rand_i: int = randi_range(0, peg_arr.size()-1)
	
	return peg_arr[rand_i]


func _exit_tree():
	for id in pooled_areas:
		PhysicsServer2D.free_rid(pooled_areas[id])
	
	if shared_shape_rid.is_valid():
		PhysicsServer2D.free_rid(shared_shape_rid)
	
	for id in pooled_agents:
		var agent_rid = pooled_agents[id]
		if agent_rid.is_valid():
			NavigationServer2D.free_rid(agent_rid)
