extends Node2D
class_name StageManager

@export var stage_nodes: Array[StageNode]
var stage_i: int = 0
var curr_stage_node: StageNode

var away_point: Vector2 = Vector2(0,5000)

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.broadcast_available_stages.emit(stage_nodes)
	SignalBus.select_stage.connect(set_stage_node)
	
	set_stage_node(stage_nodes[0])
	

#func _process(delta):
	#
	#if Input.is_action_just_pressed("ui_accept"):
		#stage_i += 1
		#if stage_i > stage_nodes.size()-1:
			#stage_i = 0
		#
		#set_stage_node(stage_nodes[stage_i])

func set_stage_node(new_stage_node: StageNode):
	if new_stage_node and new_stage_node != curr_stage_node:
		new_stage_node.global_position = global_position
		
		if curr_stage_node:
			curr_stage_node.global_position = away_point
		
		curr_stage_node = new_stage_node
