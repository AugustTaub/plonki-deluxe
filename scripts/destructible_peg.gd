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



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if destruction_queued:
		destruct_timer += delta
		if destruct_timer >= destruct_timer_length:
			destroy()
		
		if perpetrator_ball == null: 
			return
		
		var dist: float = global_position.distance_to(perpetrator_ball.global_position)
		if dist > 35:
			destroy()


func queue_destruction(destroying_ball: Ball):
	destruction_queued =  true
	perpetrator_ball = destroying_ball

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
			$peg_sprite.texture = preloaded_dead_tex
			$peg_coll_shape.disabled = true
		peg_state.REANIMATING:
			pass

func enter_peg_state(enter_state: peg_state):
	match enter_state:
		peg_state.DEFAULT:
			$peg_sprite.texture = preloaded_alive_tex
			$peg_coll_shape.disabled = false
		peg_state.DEAD:
			pass
		peg_state.REANIMATING:
			pass

#endregion


func _on_area_exited(area):
	var area_parent = area.get_parent()
	if area_parent is Ball:
		destroy()
