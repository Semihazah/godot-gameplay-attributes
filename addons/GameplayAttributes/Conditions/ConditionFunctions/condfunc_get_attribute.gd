extends ConditionFunction

enum Read {
	FINAL,
	BASE,
	BONUS,
}

export(String) var attribute_id
export(Read) var attribute_read_type
export(bool) var use_percentage
export(PoolStringArray) var attribute_tag_filter


func run_func(_target, _target2, _comparator, _magnitude, add_data = {}) -> bool:
	var attr_spec:AttributeSpec
	if _target as Blueprint:
		attr_spec = _target.get_attr_spec(attribute_id)
	elif _target as AttributeSet:
		attr_spec = _target.get_attr_spec(attribute_id)
	if not attr_spec:
		return false
	var value
	match attribute_read_type:
		Read.FINAL:
			value = attr_spec.get_filtered_final_value(attribute_tag_filter)
		Read.BASE:
			value = attr_spec._get_base_value()
		Read.BONUS:
			value = attr_spec.get_filtered_final_value(attribute_tag_filter) - \
					attr_spec._get_base_value()
	
	if use_percentage:
		var max_value = attr_spec._get_max_value()
		if max_value == 0:
			return false
		value /= max_value 
	return compare(value, _magnitude, _comparator)

func connect_spec(cond_spec:ConditionSpec) -> bool:
	var attr:AttributeSpec = cond_spec.target.get_attr_spec(attribute_id)
	if not attr:
		return false
	attr.connect("attribute_value_changed", cond_spec, "signal_condition")
	return true
