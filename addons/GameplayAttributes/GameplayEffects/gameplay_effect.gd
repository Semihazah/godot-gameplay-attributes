tool
class_name GameplayEffect
extends Resource

enum DurationType{
	INSTANT,
	DURATION,
	INFINITE,
}

enum PeriodicInhibitionPolicy {
	NEVER_RESET,
	RESET_PERIOD,
	EXECUTE_AND_RESET_PERIOD,
}

enum StackingType {
	NONE,
	AGGREGATE_BY_SOURCE,
	AGGREGATE_BY_TARGET,
}

enum StackDurationRefreshPolicy {
	REFRESH_ON_SUCCESSFUL_APPLICATION,
	NEVER_REFRESH,
}

enum StackExpirationPolicy {
	CLEAR_ENTIRE_STACK,
	REMOVE_SINGLE_STACK_AND_REFRESH_DURATION,
	REFRESH_DURATION,
}

export(String) var effect_name
export(String) var effect_ID
export(Texture) var effect_icon
export(String, FILE) var spec_scene_override

export(PoolStringArray) var tags_granted
export(PoolStringArray) var remove_effects_with_tags

export(Array, Resource) var condition_application
export(Array, Resource) var condition_ongoing

export(float) var check_conditions_timer = 0.5

export(DurationType) var duration_type
export(Resource) var duration_magnitude setget _set_duration_magnitude

export(Resource) var turn_duration_magnitude setget _set_turn_duration_magnitude
export(String) var turn_duration_signal_group = "emit_turn_signal"
export(String) var turn_duration_signal = "turn_ended"
export(bool) var turn_duration_is_premature


export(Resource) var period_magnitude setget _set_period_magnitude
export(bool) var period_execute_modifiers_on_application = true
export(PeriodicInhibitionPolicy) var period_inhibition_policy

export(Resource) var apply_chance_magnitude setget _set_apply_chance_magnitude

export(StackingType) var stack_type
export(int) var stack_limit_count = 0
export(StackDurationRefreshPolicy) var stack_duration_refresh_policy
export(StackDurationRefreshPolicy) var stack_period_reset_policy
export(StackExpirationPolicy) var stack_expiration_policy

export(Array, Resource) var overflow_effects setget _set_overflow_effects
export(bool) var overflow_deny_application
export(bool) var overflow_clear_stack

export(Array, Resource) var expiration_effects_premature setget _set_premature_expiration_effects
export(Array, Resource) var expiration_effects_routine setget _set_routine_expiration_effects

export(Array, Resource) var modifiers setget _set_modifiers

export(Dictionary) var additional_data


func get_duration_magnitude(source:Node, target:Node, add_data: = {}) -> float:
	if duration_magnitude.has_method("_calculate_magnitude"):
		return duration_magnitude._calculate_magnitude(source, target, add_data)
	else:
		return 0.0


func get_period_magnitude(source:Node, target:Node, add_data: = {}) -> float:
	if period_magnitude.has_method("_calculate_magnitude"):
		return period_magnitude._calculate_magnitude(source, target, add_data)
	else:
		return 0.0


func get_turn_duration_magnitude(source:Node, target:Node, add_data: = {}) -> int:
	if turn_duration_magnitude.has_method("_calculate_magnitude"):
		return int(turn_duration_magnitude._calculate_magnitude(source, target, add_data))
	else:
		return 0


func get_apply_chance(source:Node, target:Node, add_data: = {}) -> float:
	if apply_chance_magnitude.has_method("_calculate_magnitude"):
		return apply_chance_magnitude._calculate_magnitude(source, target, add_data)
	else:
		return 1.0

# Property Functions ***********************************************************
func _set_duration_magnitude(calculation):
	if calculation is GDScript:
		calculation = calculation.new()
	if calculation is MagnitudeCalculation:
		duration_magnitude = calculation
	elif Engine.editor_hint and duration_magnitude != calculation:
		print("Expected class: MagnitudeCalculation")

func _set_turn_duration_magnitude(calculation):
	if calculation is GDScript:
		calculation = calculation.new()
	if calculation is MagnitudeCalculation:
		turn_duration_magnitude = calculation
	elif Engine.editor_hint and turn_duration_magnitude != calculation:
		print("Expected class: MagnitudeCalculation")


func _set_period_magnitude(calculation):
	if calculation is GDScript:
		calculation = calculation.new()
	if calculation is MagnitudeCalculation:
		period_magnitude = calculation
	elif Engine.editor_hint and period_magnitude != calculation:
		print("Expected class: MagnitudeCalculation")


func _set_apply_chance_magnitude(calculation):
	if calculation is GDScript:
		calculation = calculation.new()
	if calculation is MagnitudeCalculation:
		apply_chance_magnitude = calculation
	elif Engine.editor_hint() and apply_chance_magnitude != calculation:
		print("Expected class: MagnitudeCalculation")


func _set_overflow_effects(new_array:Array):
	overflow_effects = new_array
	for i in new_array.size():
		var value = new_array[i]
		if value is GDScript:
			value = value.new()
			if value as GameplayEffect:		# Do not remove "as". Prevents editor bug
				overflow_effects[i] = value
		elif not value as GameplayEffect:
			overflow_effects[i] == null
			if Engine.editor_hint:
				print("Expected class: GameplayEffect")


func _set_premature_expiration_effects(new_array:Array):
	expiration_effects_premature = new_array
	for i in new_array.size():
		var value = new_array[i]
		if value is GDScript:
			value = value.new()
			if value as GameplayEffect:
				expiration_effects_premature[i] = value
		elif not value as GameplayEffect:
			expiration_effects_premature[i] == null
			if Engine.editor_hint:
				print("Expected class: GameplayEffect")


func _set_routine_expiration_effects(new_array:Array):
	expiration_effects_routine = new_array
	for i in new_array.size():
		var value = new_array[i]
		if value is GDScript:
			value = value.new()
			if value as GameplayEffect:
				expiration_effects_routine[i] = value
		elif not value as GameplayEffect:
			expiration_effects_routine[i] == null
			if Engine.editor_hint:
				print("Expected class: GameplayEffect")


func _set_modifiers(new_array:Array):
	modifiers = new_array
	for i in new_array.size():
		var value = new_array[i]
		if value is GDScript:
			value = value.new()
			if value is GameplayEffectModifier:
				modifiers[i] = value
		elif not value is GameplayEffectModifier:
			modifiers[i] == null
			if Engine.editor_hint:
				print("Expected class: GameplayEffectModifier")
