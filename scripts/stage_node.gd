extends Node2D

class_name StageNode


@export_category("upgrades")
@export var associated_peg_upgrade: UpgradeData 
@export var unlock_upgrade: UpgradeData 

@export_category("other")

@export var nr_of_free_pegs: int = 3

@export var navigation_region: NavigationRegion2D


var peg_nodes: Array[DestructiblePeg]
var locked_peg_nodes: Array[DestructiblePeg]

var upgrade_preloader: ResourcePreloader

func _ready():
	
	if $pegs:
		for child in $pegs.get_children():
			if child is DestructiblePeg:
				peg_nodes.append(child)
	
	
	SignalBus.workshop_toggled.connect(update_peg_amount_from_save)
	SignalBus.options_toggled.connect(update_peg_amount_from_save)
	
	SignalBus.upgrade_preloader_loaded.connect(_on_upgrade_preloader_loaded)
	
	await SignalBus.upgrade_preloader_loaded
	
	update_peg_amount_from_save()

func _on_upgrade_preloader_loaded(preloader: ResourcePreloader):
	upgrade_preloader = preloader

func unlock_pegs(peg_amount: int):
	if locked_peg_nodes.size() == 0: 
		push_warning("DestructiblePeg: Tried to unlock a peg but there was no locked pegs!")
		return
	
	for i in peg_amount:
		var new_unlocked_peg: DestructiblePeg = locked_peg_nodes.pop_front()
		new_unlocked_peg.set_unlock_state(true)

func lock_pegs(peg_amount: int):
	var unlocked_amount: int = 0
	var i: int = 0
	while unlocked_amount < peg_amount:
		var new_locked_peg_candidate: DestructiblePeg = peg_nodes[i]
		
		if not locked_peg_nodes.has(new_locked_peg_candidate):
			locked_peg_nodes.append(new_locked_peg_candidate)
			new_locked_peg_candidate.set_unlock_state(false)
			unlocked_amount += 1
		
		i += 1
		

func set_unlocked_pegs_amount(new_amount):
	var unlocked_amount: int = peg_nodes.size() - locked_peg_nodes.size()
	var difference: int = abs(new_amount - unlocked_amount)
	
	if new_amount > unlocked_amount:
		unlock_pegs(difference)
	else:
		lock_pegs(difference)

func update_peg_amount_from_save():
	if associated_peg_upgrade:
		
		var unlocked_pegs_upgrade: UpgradeData = associated_peg_upgrade
		var unlocked_lvl: int = SaveManager.get_upgrade_level_by_name(associated_peg_upgrade.name)
		
		nr_of_free_pegs = unlocked_pegs_upgrade.get_level_result(unlocked_lvl)
		
	else:
		push_warning("Stage: Could not find associated peg amount upgrade!")
	
	set_unlocked_pegs_amount(nr_of_free_pegs)
