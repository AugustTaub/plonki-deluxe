extends Node2D
class_name BallBucketController

@onready var payout_label: RichTextLabel = %payout_label
@onready var vis_body: Node2D = %vis_body
@onready var coll_shape: CollisionShape2D = %bucket_coll_shape

var speed: float = 100.0
var cooldown_time: float = 5.0
var going_right: bool = true

# State management variables
var active: bool = true
var is_unlocked: bool = false
var is_on_cooldown: bool = false 

@onready var play_area_rect: Rect2 = GlobalVars.play_area_rect
@export var associated_upgrade: UpgradeData

func _ready():
	SignalBus.coins_increased.connect(_on_coins_increased)
	SignalBus.options_toggled.connect(update_from_save)
	SignalBus.workshop_toggled.connect(update_from_save)
	
	update_payout_label()
	update_from_save()

func update_from_save():
	if not associated_upgrade: return
	
	is_unlocked = SaveManager.save_game.unlocked_upgrades.has(associated_upgrade)
	_evaluate_activation()

func start_cooldown():
	if is_on_cooldown or not is_unlocked: return
	
	is_on_cooldown = true
	_evaluate_activation()
	
	await get_tree().create_timer(cooldown_time).timeout
	
	is_on_cooldown = false
	_evaluate_activation()

func _evaluate_activation():
	var should_be_active: bool = is_unlocked and not is_on_cooldown
	
	if should_be_active != active:
		active = should_be_active
		set_activation(active)

func _on_coins_increased(_amount: int):
	update_payout_label()

func update_payout_label():
	payout_label.text = "+" + str(int(CsCalculator.curr_cs * 5))

func _physics_process(delta):
	
	var goal_x: float = 0
	
	if going_right:
		global_position.x += delta * speed
		goal_x = play_area_rect.position.x + play_area_rect.size.x
	else:
		global_position.x -= delta * speed
		goal_x = play_area_rect.position.x
	
	var dist: float = abs(global_position.x - goal_x)
	if dist <= 24:
		going_right = !going_right

func set_activation(new_active: bool):
	match new_active:
		true:
			vis_body.show()
			
			var tween = create_tween()
			tween.tween_property(vis_body, "position:y", 0, 0.4)
			
			coll_shape.disabled = false
			
		false:
			
			coll_shape.disabled = true
			
			var tween = create_tween()
			tween.tween_property(vis_body, "position:y", 90, 1.0)
			
			await tween.finished
			vis_body.hide()
