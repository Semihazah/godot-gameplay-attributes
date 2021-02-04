extends "res://addons/GameplayAttributes/Blueprint/datablock.gd"
class_name WorldDatablock
# controls physical representation of this object.
signal shell_model_changed(blueprint, old_model, new_model)

enum Gender_Type {
	OBJECT,
	GENDERLESS,
	MALE,
	FEMALE,
	NONBINARY,
	GENDERFLUID,
}

export(PackedScene) var shell_model setget _set_shell_model
export(Gender_Type) var shell_gender
var shell

func _init():
	datablock_type_id = "WorldDatablock"


func _set_shell_model(new_model):
	emit_signal("shell_model_changed", blueprint, shell_model, new_model)
	shell_model = new_model


func _spawn_shell() -> Node:
	return null
