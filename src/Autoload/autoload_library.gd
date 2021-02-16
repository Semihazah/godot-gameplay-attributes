extends Node

enum Comparator {
	EQUAL = OP_EQUAL,
	NOT_EQUAL = OP_NOT_EQUAL,
	LESS = OP_LESS,
	LESS_EQUAL = OP_LESS_EQUAL,
	GREATER = OP_GREATER,
	GREATER_EQUAL = OP_GREATER_EQUAL,
}

enum TargetingMethod {
	SINGLE,
	ALL,
	ALL_ENEMIES,
	ALL_ALLIES,
	AREA,
	CUSTOM,
}

enum AttributeReadType {
	FINAL,
	BASE,
	BONUS,
}
static func merge_dir(target, patch, merge_arrays = false):
	for key in patch:
		if target.has(key):
			var tv = target[key]
			if typeof(tv) == TYPE_DICTIONARY:
				merge_dir(tv, patch[key])
			elif merge_arrays and typeof(tv) == TYPE_ARRAY:
				tv += patch[key]
			else:
				target[key] = patch[key]
		else:
			target[key] = patch[key]


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


static func get_children_in_group(node:Node, group:String) -> Array:
	var return_array = []
	for child in node.get_children():
		if child.is_in_group(group):
			return_array.append(child)
	return return_array


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
