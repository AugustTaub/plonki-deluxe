extends Node

@warning_ignore("unused_signal")
signal spawn_ball(ball_pos: Vector2, ball_vel: Vector2,radius: float)

@warning_ignore("unused_signal")
signal spawn_simulated_ball(ball_pos: Vector2, ball_vel: Vector2,radius: float)

@warning_ignore("unused_signal")
signal spawn_shock_wave(wave_pos: Vector2, wave_size: float, wave_life_time: float)

### UI
@warning_ignore("unused_signal")
signal workshop_toggled()

@warning_ignore("unused_signal")
signal set_money_counter(new_amount: int)

###

@warning_ignore("unused_signal")
signal save_game_loaded()

###

@warning_ignore("unused_signal")
signal upgrade_preloader_loaded(preloader_node: ResourcePreloader)
