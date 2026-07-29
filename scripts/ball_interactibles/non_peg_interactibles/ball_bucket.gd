extends BallInteractibleObject

class_name BallBucket


func perform_interaction(ball_data: BallManager.BallData) -> BallManager.BallData:
	
	ball_data.active = false
	
	var payout: int = int(CsCalculator.curr_cs * 5)
	SaveManager.change_money_with_vis_nr_no_signal(payout,global_position)
	
	var parent = get_parent()
	
	if parent is BallBucketController:
		
		parent.start_cooldown()
		
		if parent.vis_body:
			var tween = create_tween()
			tween.tween_property(parent.vis_body,"position:y",12,0.1)
			tween.tween_property(parent.vis_body,"position:y",0,0.3)
	
	SignalBus.play_sound.emit("plomp_lower")
	
	return ball_data
