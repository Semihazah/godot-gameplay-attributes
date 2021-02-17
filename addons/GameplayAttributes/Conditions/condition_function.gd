class_name ConditionFunction
extends Resource

enum Comparator {
	EQUAL = OP_EQUAL,
	NOT_EQUAL = OP_NOT_EQUAL,
	LESS = OP_LESS,
	LESS_EQUAL = OP_LESS_EQUAL,
	GREATER = OP_GREATER,
	GREATER_EQUAL = OP_GREATER_EQUAL,
}

export(bool) var event_run = false

func run_func(_target, _target2, _comparator, _magnitude, _add_data = {}) -> bool:
	return false

func _to_string():
	return ""


static func compare(value_a, value_b, comparator) -> bool:
	match comparator:
		Comparator.EQUAL:
			if value_a == value_b:
				return true
		Comparator.NOT_EQUAL:
			if value_a != value_b:
				return true
		Comparator.LESS:
			if value_a < value_b:
				return true
		Comparator.LESS_EQUAL:
			if value_a <= value_b:
				return true
		Comparator.GREATER:
			if value_a > value_b:
				return true
		Comparator.GREATER_EQUAL:
			if value_a >= value_b:
				return true
	return false


func connect_spec(cond_spec:ConditionSpec) -> bool:
	return false
