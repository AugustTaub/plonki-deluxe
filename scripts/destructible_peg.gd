extends Area2D

class_name DestructiblePeg

var destruction_queued: bool = false
var destruct_timer: float = 0
var destruct_timer_length: float = 0
var perpetrator_ball: Ball


enum peg_state{DEFAULT,DEAD,REANIMATING}
var curr_peg_state: peg_state = peg_state.DEFAULT

var preloaded_alive_tex: Texture2D = preload("res://2D/godot_gen_textures/alive_circle_peg.tres")
var preloaded_dead_tex: Texture2D = preload("res://2D/godot_gen_textures/dead_circle_peg.tres")

var HP: int = 3


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if destruction_queued:
		destruct_timer += delta
		if destruct_timer >= destruct_timer_length:
			destroy()
		


func queue_destruction():
	destroy()



func destroy():
	change_peg_state(peg_state.DEAD)



#region State Machine

func change_peg_state(new_state: peg_state):
	exit_peg_state(curr_peg_state)
	enter_peg_state(new_state)
	
	curr_peg_state = new_state

func exit_peg_state(exit_state: peg_state):
	match exit_state:
		peg_state.DEFAULT:
			pass
		peg_state.DEAD:
			$peg_sprite.texture = preloaded_alive_tex
			$peg_coll_shape.disabled = false
			
			
		peg_state.REANIMATING:
			pass

func enter_peg_state(enter_state: peg_state):
	match enter_state:
		peg_state.DEFAULT:
			pass
		peg_state.DEAD:
			
			$peg_sprite.texture = preloaded_dead_tex
			$peg_coll_shape.disabled = true
			
			change_peg_state(peg_state.REANIMATING)
		peg_state.REANIMATING:
			await get_tree().create_timer(0.5).timeout
			change_peg_state(peg_state.DEFAULT)

#endregion
