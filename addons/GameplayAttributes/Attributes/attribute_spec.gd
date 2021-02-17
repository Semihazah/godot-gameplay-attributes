class_name AttributeSpec
extends Reference

signal attribute_value_changed(id, previous_value, new_value)
signal attribute_value_min_reached(id, new_value, min_value)
signal attribute_value_max_reached(id, new_value, max_value)

var parent_attribute_set
var attribute_data:Attribute

func _init(attr:Attribute, value, add_data = {}):
#	print("Initializing attribute %s, base = %s" % [attr.attribute_id, value])
	attribute_data = attr
	self._base_value = value
	_additional_data = add_data

var _base_value: float setget _set_base_value, _get_base_value

var _raw_modifiers:Array = []
var _final_modifiers:Array = []

var _final_value: float setget , _get_final_value
var _cached_value: float

var _additional_data: = {}

var lock_attribute: = false

func _add_attribute(attr_set, data = {}):
	parent_attribute_set = attr_set
	connect("attribute_value_changed", attr_set, "on_attribute_value_changed")
	connect("attribute_value_min_reached", attr_set, "on_attribute_value_min_reached")
	connect("attribute_value_max_reached", attr_set, "on_attribute_value_max_reached")


func _remove_attribute(attr_set, data = {}):
	parent_attribute_set = null
	disconnect("attribute_value_changed", attr_set, "on_attribute_value_changed")
	disconnect("attribute_value_min_reached", attr_set, "on_attribute_value_min_reached")
	disconnect("attribute_value_max_reached", attr_set, "on_attribute_value_max_reached")


func _set_base_value(new_value: float):
	if not lock_attribute:
		_base_value = new_value
		var cache = _cached_value
		emit_signal("attribute_value_changed", attribute_data.attribute_id, cache, self._final_value)


func _get_base_value():
	if parent_attribute_set:
		var data = parent_attribute_set.get_parent()
		if data and attribute_data.base_value_calculation:
			return _base_value + attribute_data.base_value_calculation._calculate_magnitude(data, data)
	return _base_value


func get_filtered_final_value(tag_filter: = []) -> float:
	return calculate_value(self._base_value, tag_filter)


func _get_final_value() -> float:
	if lock_attribute:
		return _cached_value
	_cached_value = calculate_value(self._base_value)
	return _cached_value

func add_modifier(mod:GameplayEffectModifierSpec):
	if mod.affects_base:
		apply_base_modifier(mod)
	if mod.gameplay_effect_modifier.is_final:
		add_final_modifier(mod)
	else:
		add_raw_modifier(mod)


func add_raw_modifier(mod):
	_raw_modifiers.push_back(mod)
	if not lock_attribute:
		var cache = _cached_value
		emit_signal("attribute_value_changed", attribute_data.attribute_id, cache, self._final_value)


func add_final_modifier(mod):
	_final_modifiers.push_back(mod)
	if not lock_attribute:
		var cache = _cached_value
		emit_signal("attribute_value_changed", attribute_data.attribute_id, cache, self._final_value)


func remove_raw_modifier(mod, emit):
	if _raw_modifiers.has(mod):
		_raw_modifiers.erase(mod)
		if emit and not lock_attribute:
			var cache = _cached_value
			emit_signal("attribute_value_changed", attribute_data.attribute_id, cache, self._final_value)
	


func remove_final_modifier(mod, emit = true):
	if _final_modifiers.has(mod):
		_final_modifiers.erase(mod)
		if emit and not lock_attribute:
			var cache = _cached_value
			emit_signal("attribute_value_changed", attribute_data.attribute_id, cache, self._final_value)


func apply_raw_modifiers(var input, tag_filter: = []):
	if _raw_modifiers.empty():
		return input
	var delete_queue: = []
	var add_value = 0.0
	var multi_value = 0.0
	var divide_value = 0.0
	var override_value = 0.0
	var trigger_override = false
	for mod in _raw_modifiers:
		if mod.queue_delete:
			delete_queue.append(mod)
		elif mod.get_is_enabled():
			if has_all_tags(mod.gameplay_effect_modifier.tags, tag_filter):
				match mod.get_operation_type():
					GameplayEffectModifier.OperationType.ADD:
						add_value += mod.get_magnitude()
					GameplayEffectModifier.OperationType.MULTIPLY:
						multi_value += mod.get_magnitude()
					GameplayEffectModifier.OperationType.DIVIDE:
						divide_value += mod.get_magnitude()
					GameplayEffectModifier.OperationType.OVERRIDE:
						override_value = mod.get_magnitude()
						trigger_override = true

	divide_value += 1
	if divide_value == 0:
		divide_value = 1
	multi_value += 1.0
	delete_queued_modifiers(delete_queue, false)
	
	if trigger_override:
		return override_value
	else:
		return ((input + add_value) * multi_value) / divide_value


func apply_final_modifiers(var input, tag_filter: = []):
	if _final_modifiers.empty():
		return input
	var delete_queue: = []
	var add_value = 0.0
	var multi_value = 0.0
	var divide_value = 0.0
	var override_value = 0.0
	var trigger_override = false
	for mod in _final_modifiers:
		if mod.queue_delete:
			delete_queue.append(mod)
		elif mod.get_is_enabled():
			if has_all_tags(mod.gameplay_effect_modifier.tags, tag_filter):
				match mod.get_operation_type():
					GameplayEffectModifier.OperationType.ADD:
						add_value += mod.get_magnitude()
					GameplayEffectModifier.OperationType.MULTIPLY:
						multi_value += mod.get_magnitude()
					GameplayEffectModifier.OperationType.DIVIDE:
						divide_value += mod.get_magnitude()
					GameplayEffectModifier.OperationType.OVERRIDE:
						override_value = mod.get_magnitude()
						trigger_override = true
	divide_value += 1
	if divide_value == 0:
		divide_value = 1
	multi_value += 1.0
		
	delete_queued_modifiers(delete_queue, true)
	
	if trigger_override:
		return override_value
	else:
		return ((input + add_value) * multi_value) / divide_value


func delete_queued_modifiers(mod_array:Array, is_final:bool):
	for mod in mod_array:
		if is_final:
			remove_final_modifier(mod, false)
		else:
			remove_raw_modifier(mod, false)
#		mod.queue_free() probably don't need this, modifiers are reference counted

func _get_min_value():
	if parent_attribute_set and attribute_data.min_value_mag_calc is MagnitudeCalculation:
		var data = parent_attribute_set.get_parent()
		return attribute_data.min_value_mag_calc._calculate_magnitude(data, data)
	else:
		return null


func _get_max_value():
	if parent_attribute_set and attribute_data.max_value_mag_calc is MagnitudeCalculation:
		var data = parent_attribute_set.get_parent()
		return attribute_data.max_value_mag_calc._calculate_magnitude(data, data)
	else:
		return null


func calculate_value(base:float, tag_filter: = PoolStringArray())->float:
	var _working_value = base
	_working_value = apply_raw_modifiers(_working_value, tag_filter)
	_working_value = apply_final_modifiers(_working_value, tag_filter)
	
	var min_value = _get_min_value()
	if min_value != null and _working_value <= min_value:
		emit_signal("attribute_value_min_reached", attribute_data.attribute_id, _working_value, min_value)
		_working_value = min_value
	
	var max_value = _get_max_value()
	if max_value != null and _working_value >= max_value:
		emit_signal("attribute_value_max_reached", attribute_data.attribute_id, _working_value, max_value)
		_working_value = max_value
	
	return _working_value


func has_all_tags(search_list:Array, filter:Array) -> bool:
	for tag in filter:
		if not search_list.has(tag):
			return false
	return true


func apply_base_modifier(mod:GameplayEffectModifierSpec):
	var mag = mod.get_magnitude()
	_base_value += mag
	var cache = _cached_value
	
	emit_signal("attribute_value_changed", attribute_data.attribute_id, cache, self._final_value)


# Data Functions ***************************************************************
func _save() -> Dictionary:
	var save_dict = {
		"script":get_script().resource_path,
		"attribute_resource":attribute_data.resource_path,
		"additional_data":_additional_data,
		"locked":lock_attribute,
		"base":_base_value,
		"connections":get_incoming_connections(),
	}
	return save_dict


func _load(load_dict:Dictionary) -> bool:
	attribute_data = load(load_dict["attribute_resource"])
	_additional_data = load_dict["additional_data"]
	lock_attribute = load_dict["locked"]
	_base_value = load_dict["base"]
	for connect_dict in load_dict["connections"]:
		parent_attribute_set.get_node(connect_dict["source"]).connect(connect_dict["signal_name"], self, connect_dict["method_name"])
	return true
