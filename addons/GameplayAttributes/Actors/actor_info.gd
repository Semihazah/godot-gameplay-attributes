class_name ActorInfo
extends ShellDatablock
# Used to represent a person or other actor in the world.
# Will eventually hold character logic and dialogue

signal actor_name_changed
signal actor_portrait_changed
signal actor_description_changed


export(String) var actor_name setget _set_actor_name, _get_actor_name
export(Texture) var actor_portrait setget _set_actor_portrait
export(String) var actor_description setget _set_actor_description
export(Array, Resource) var actor_factions

func _connect_to_blueprint(new_blueprint):
	new_blueprint.name_func = funcref(self, "_get_actor_name")
	new_blueprint.icon_func = funcref(self, "_get_actor_icon")
	new_blueprint.faction_func = funcref(self, "_get_faction_list")
	new_blueprint.desc_func = funcref(self, "_get_actor_desc")
	new_blueprint.shell_func = funcref(self, "_get_shell")


func _get_actor_name():
	return actor_name


func _get_actor_icon():
	return actor_portrait


func _get_actor_desc():
	return actor_description


func _get_faction_list():
	return actor_factions


func _set_actor_name(new_name):
	emit_signal("actor_name_changed", actor_name, new_name)
	actor_name = new_name


func _set_actor_portrait(new_portrait):
	emit_signal("actor_portrait_changed", actor_portrait, new_portrait)
	actor_portrait = new_portrait


func _set_actor_description(new_description):
	emit_signal("actor_description_changed", actor_description, new_description)
	actor_description = new_description


func _spawn_shell() -> Node:
	if shell and shell.has_method("_disconnect_from_datablock"):
		shell._disconnect_from_datablock()
	shell = shell_scene.instance()
	if shell.has_method("_connect_to_datablock"):
		shell._connect_to_datablock(self)
	return shell

# Data Functions ***************************************************************
func _save() -> Dictionary:
	var save_dict = {
		"script": get_script(),
		"actor_name": self.actor_name,
		"actor_description":self.actor_description,
		"shell_scene":shell_scene,
		"gender_type":shell_gender,
	}
	if self.actor_portrait:
		save_dict["actor_portait"] = self.actor_portrait.resource_path
	var faction_paths = []
	for faction in self.actor_factions:
		faction_paths.append(faction.resource_path)
	save_dict["actor_factions"] = faction_paths
	
	if shell.has_method("_save"):
		save_dict["shell"] = shell._save()
	return save_dict
