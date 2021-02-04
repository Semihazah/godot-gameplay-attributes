tool
class_name Condition
extends Resource

enum TargetSelect{
	SOURCE,
	TARGET,
#	REFERENCE,
}
enum Comparator {
	EQUAL = OP_EQUAL,
	NOT_EQUAL = OP_NOT_EQUAL,
	LESS = OP_LESS,
	LESS_EQUAL = OP_LESS_EQUAL,
	GREATER = OP_GREATER,
	GREATER_EQUAL = OP_GREATER_EQUAL,
}
export(TargetSelect) var target_select
export(Resource) var function setget _set_function
export(Comparator) var comparator
export(Resource) var magnitude_func setget _set_mag_function

func check_condition(source, target, add_data = {}) -> bool:
	var actor1
	var actor2
	match target_select:
		TargetSelect.SOURCE:
			actor1 = source
			actor2 = target
		TargetSelect.TARGET:
			actor1 = target
			actor2 = source
	if not actor1:
		return false
	magnitude_func = magnitude_func as MagnitudeCalculation
	if not magnitude_func:
		return false
	var mag = magnitude_func._calculate_magnitude(source, target)
	return function.run_func(actor1, actor2, comparator, mag, add_data)


func get_string(source:Blueprint, target:Blueprint):
	var target_string
	if target_select == TargetSelect.SOURCE:
		target_string = source._to_string()
	elif target:
		target_string = target._to_string()
	else:
		target_string = "target"
	
	var function_string = function._to_string()
	
	var comparator_string = comparator_to_string(comparator)
	
	var magnitude_string = magnitude_func._calculate_magnitude(source, target)
	return "%s %s %s %s." % [target_string, function_string, comparator_string, magnitude_string]

# Property Functions ***********************************************************
func _set_function(new_function):
	if new_function is GDScript:
		new_function = new_function.new()
	if new_function is ConditionFunction:
		function = new_function
	elif Engine.editor_hint and function != new_function:
		print("Expected class: ConditionFunction")


func _set_mag_function(new_function):
	if new_function is GDScript:
		new_function = new_function.new()
	if new_function is MagnitudeCalculation:
		magnitude_func = new_function
	elif Engine.editor_hint and magnitude_func != new_function:
		print("Expected class: MagnitudeCalculation")

# Utility Functions ************************************************************
func comparator_to_string(c:int):
	match c:
		Comparator.EQUAL:
			return "equals"
		Comparator.NOT_EQUAL:
			return "not equal to"
		Comparator.LESS:
			return "less than"
		Comparator.LESS_EQUAL:
			return "less than or equal to"
		Comparator.GREATER:
			return "more than"
		Comparator.GREATER_EQUAL:
			return "more than or equal to"
	return "??"
