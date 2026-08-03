extends Node

const SUFFIXES: Array[String] = ["", "k", "m", "b", "t"]


func amount_to_string(money_amount: int) -> String:
	var abs_amount: float = float(abs(money_amount))
	
	if abs_amount < 1000.0:
		return str(money_amount)
	
	var suffix_index: int = 0
	
	while abs_amount >= 999.95 and suffix_index < SUFFIXES.size() - 1:
		abs_amount /= 1000.0
		suffix_index += 1
	
	var formatted: String = "%.1f" % abs_amount
	
	if formatted.ends_with(".0"):
		formatted = formatted.left(-2)
		
	var prefix: String = "-" if money_amount < 0 else ""
	return prefix + formatted + SUFFIXES[suffix_index]
