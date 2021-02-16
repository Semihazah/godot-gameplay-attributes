extends Node


var references = {}

func add_blueprint_ref(bp, replace = false):
	var id = bp.blueprint_id
	if not id:
		return
	if references.has(id):
		if replace:
			references[id] = bp
		else:
			if references[id] is Array:
				references[id].append(bp)
			else:
				references[id] = [references[id], bp]
	else:
		references[id] = bp
