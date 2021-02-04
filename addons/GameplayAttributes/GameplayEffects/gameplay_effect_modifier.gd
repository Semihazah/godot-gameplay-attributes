tool
extends Resource
class_name GameplayEffectModifier
# Data resource describing how modifier specs operate.
enum OperationType {
	ADD,
	MULTIPLY,
	DIVIDE,
	OVERRIDE,
}


export(String) var attribute_id

export(OperationType) var modifier_operation
export(Resource) var modifier_magnitude setget _set_modifier_magnitude
export(bool) var modifier_is_final = false
export(PoolStringArray) var modifier_tags


export(PoolStringArray) var tags_source_require
export(PoolStringArray) var tags_source_ignore

export(PoolStringArray) var tags_target_require
export(PoolStringArray) var tags_target_ignore

export(Script) var modifier_spec_override

func get_magnitude(source_data, target_data, add_data = {}):
	return modifier_magnitude._calculate_magnitude(source_data, target_data, add_data)


# Property Functions ***********************************************************
func _set_modifier_magnitude(new_function):
	if new_function is GDScript:
		new_function = new_function.new()
	if new_function is MagnitudeCalculation:
		modifier_magnitude = new_function
	elif Engine.editor_hint and modifier_magnitude != new_function:
		print("Expected class: MagnitudeCalculation")
