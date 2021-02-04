extends Node

export(bool) var initialize_active = true
var datablock_type_id:String = ""
var blueprint

func _connect_to_blueprint(new_blueprint):
	blueprint = new_blueprint
	if initialize_active and datablock_type_id:
		blueprint.active_datablocks[datablock_type_id] = self
