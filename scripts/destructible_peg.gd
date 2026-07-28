extends Area2D

class_name DestructiblePeg

var destruction_queued: bool = false
var destruct_timer: float = 0
var destruct_timer_length: float = 0
var perpetrator_ball: Ball

enum peg_state {DEFAULT, DYING, REANIMATING}
var curr_peg_state: peg_state = peg_state.DEFAULT

@export_category("nodes")
@export var peg_sprite: Node2D
@export var peg_coll_shape: Node2D

@export_category("textures")
@export var preloaded_alive_tex: Texture2D = preload("res://2D/godot_gen_textures/alive_circle_peg.tres")
@export var preloaded_dead_tex: Texture2D = preload("res://2D/godot_gen_textures/dead_circle_peg.tres")

@export var HP: int = 2
@export var value: int = 1
@export var reanimate_time: float = 2.0

@onready var peg_sprite_start_scale: Vector2 = peg_sprite.scale

var reanimate_timer: float = 0.0

func _ready():
	pass

func _process(delta):
	if destruction_queued:
		destruct_timer += delta
		if destruct_timer >= destruct_timer_length:
			destroy()
	
	match curr_peg_state:
		peg_state.DEFAULT:
			pass
		peg_state.DYING:
			pass
		peg_state.REANIMATING:
			reanimate_timer += delta
			if reanimate_timer >= reanimate_time:
				reanimate_timer = 0.0
				change_peg_state(peg_state.DEFAULT)

func queue_destruction():
	destroy()

func destroy_without_payout():
	if curr_peg_state != peg_state.DEFAULT:
		return
	
	change_peg_state(peg_state.DYING)

func destroy():
	SaveManager.change_money_with_vis_nr(1, global_position)
	destroy_without_payout()

#region State Machine

func change_peg_state(new_state: peg_state):
	exit_peg_state(curr_peg_state)
	enter_peg_state(new_state)
	curr_peg_state = new_state

func exit_peg_state(exit_state: peg_state):
	match exit_state:
		peg_state.DEFAULT:
			pass
		peg_state.DYING:
			pass
		peg_state.REANIMATING:
			
			peg_sprite.texture = preloaded_alive_tex
			peg_coll_shape.disabled = false

func enter_peg_state(enter_state: peg_state):
	match enter_state:
		peg_state.DEFAULT:
			pass
		peg_state.DYING:
			
			peg_coll_shape.disabled = true
			
			var tween: Tween = create_tween()
			tween.tween_property(peg_sprite, "scale", peg_sprite_start_scale * 1.3, 0.1).set_trans(Tween.TRANS_BOUNCE)
			tween.tween_property(peg_sprite, "scale", peg_sprite_start_scale, 0.1)
			
			await tween.finished
			
			peg_sprite.scale = peg_sprite_start_scale
			peg_sprite.texture = preloaded_dead_tex
			
			change_peg_state(peg_state.REANIMATING)
			
		peg_state.REANIMATING:
			reanimate_timer = 0.0
			
#endregion
