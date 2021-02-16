extends "res://addons/GameplayAttributes/Blueprint/datablock.gd"
class_name ShellDatablock
# controls physical representation of this object.
signal shell_scene_changed(blueprint, old_scene, new_scene)
signal shell_changed(blueprint, old_shell, new_shell)

enum Gender_Type {
	OBJECT,
	GENDERLESS,
	MALE,
	FEMALE,
	NONBINARY,
	GENDERFLUID,
}

export(PackedScene) var shell_scene setget _set_shell_scene
export(Gender_Type) var shell_gender
var shell setget _set_shell, _get_shell

func _init():
	datablock_type_id = "ShellDatablock"


func _set_shell_scene(new_scene):
	emit_signal("shell_scene_changed", blueprint, shell_scene, new_scene)
	shell_scene = new_scene


func _spawn_shell() -> Node:
	return null


func _set_shell(new_shell):
	emit_signal("shell_changed", blueprint, shell, new_shell)
	shell = new_shell
	


func _get_shell():
	return shell
