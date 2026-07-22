extends Node

### ball signals

@warning_ignore("unused_signal")
signal spawn_ball(ball_pos: Vector2, ball_vel: Vector2,radius: float)

@warning_ignore("unused_signal")
signal spawn_simulated_ball(ball_pos: Vector2, ball_vel: Vector2,radius: float)

### VFX Signals

@warning_ignore("unused_signal")
signal spawn_shock_wave(wave_pos: Vector2, wave_size: float, wave_life_time: float)

### infested peg signals

@warning_ignore("unused_signal")
signal spawn_infested_peg(peg_pos: Vector2)

### UI
@warning_ignore("unused_signal")
signal workshop_toggled()

@warning_ignore("unused_signal")
signal set_money_counter(new_amount: int)

@warning_ignore("unused_signal")
signal set_ball_counter(new_amount: int)

@warning_ignore("unused_signal")
signal broadcast_available_stages(stages: Array[StageNode])

@warning_ignore("unused_signal")
signal select_stage(new_stage: StageNode)

###

@warning_ignore("unused_signal")
signal save_game_loaded()

###

@warning_ignore("unused_signal")
signal upgrade_preloader_loaded(preloader_node: ResourcePreloader)
