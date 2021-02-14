extends Node

export(bool) var initialize_active = true
var datablock_type_id:String = ""
var blueprint

func connect_to_blueprint(b:Blueprint):
	blueprint = b
	if initialize_active and datablock_type_id:
		blueprint.set_active_db(datablock_type_id, b.get_path_to(self))
	for child in get_children():
		if child.has_method("connect_to_blueprint"):
			child.connect_to_blueprint(b)
	_connect_to_blueprint(b)


func _connect_to_blueprint(blueprint):
	pass

# Data Functions ***************************************************************
func _save() -> Dictionary:
	return {}
