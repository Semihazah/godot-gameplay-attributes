tool
extends Resource
class_name Attribute

export(String) var attribute_id
export(String) var display_name
export(String) var display_short_name
export(Texture) var attribute_icon

export(bool) var display_in_menus = true
export(String, FILE) var attribute_spec_object

export(Resource) var base_value_calculation setget _set_base_value_calc

export(Resource) var min_value_mag_calc setget _set_min_value_calc
export(Resource) var max_value_mag_calc setget _set_max_value_calc

export(Dictionary) var additional_info


# Property Functions ***********************************************************
func _set_base_value_calc(new_function):
	if new_function is GDScript:
		new_function = new_function.new()
	if new_function is MagnitudeCalculation:
		base_value_calculation = new_function
	elif Engine.editor_hint and base_value_calculation != new_function:
		print("Expected class: MagnitudeCalculation")
func _set_min_value_calc(new_function):
	if new_function is GDScript:
		new_function = new_function.new()
	if new_function is MagnitudeCalculation:
		min_value_mag_calc = new_function
	elif Engine.editor_hint and min_value_mag_calc != new_function:
		print("Expected class: MagnitudeCalculation")
		
func _set_max_value_calc(new_function):
	if new_function is GDScript:
		new_function = new_function.new()
	if new_function is MagnitudeCalculation:
		max_value_mag_calc = new_function
	elif Engine.editor_hint and max_value_mag_calc != new_function:
		print("Expected class: MagnitudeCalculation")
