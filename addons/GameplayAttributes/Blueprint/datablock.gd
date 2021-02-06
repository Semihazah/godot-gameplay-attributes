extends Node

export(bool) var initialize_active = true
var datablock_type_id:String = ""
var blueprint

func connect_to_blueprint(b):
	blueprint = b
	if initialize_active and datablock_type_id:
		blueprint.active_datablocks[datablock_type_id] = self
	for child in get_children():
		if child.has_method("connect_to_blueprint"):
			child.connect_to_blueprint(b)
	_connect_to_blueprint(b)


func _connect_to_blueprint(blueprint):
	pass
