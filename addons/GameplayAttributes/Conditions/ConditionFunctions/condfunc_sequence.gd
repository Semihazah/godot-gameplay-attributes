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

