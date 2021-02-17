extends ConditionFunction

export(Array) var subconditions

func run_func(target, target2, comparator, magnitude, add_data = {}) -> bool:
	for c in subconditions:
		if not c as Condition:
			return false
			
		var response = c.check_condition(target, target2, add_data)

		if response != false:
			return response

	return true

func connect_spec(cond_spec:ConditionSpec) -> bool:
	for cond in subconditions:
		if not cond is Condition or \
				not cond.function or \
				not cond.function.connect_spec(cond_spec):
			return false
	return true
