extends Resource
class_name SaveGame


@export var money_amount: int = 0
@export var unlocked_upgrades: Array[UpgradeData]

@export var upgrade_levels: Dictionary[UpgradeData,int]
