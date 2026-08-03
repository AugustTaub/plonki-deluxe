extends Control

const SUFFIXES: Array[String] = ["", "k", "m", "b", "t"]

func _ready() -> void:
	SignalBus.set_money_counter.connect(set_money)


func set_money(new_amount: int) -> void:
	$money.text = MoneyTextShortener.amount_to_string(new_amount)
	$money.tooltip_text = str(new_amount) + " Coins"
