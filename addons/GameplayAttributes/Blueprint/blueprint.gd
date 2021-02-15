class_name Blueprint
extends Node

onready var Datablock = load("res://addons/GameplayAttributes/Blueprint/datablock.gd")

export(String) var blueprint_id
export(PoolStringArray) var default_tags

var tagContainer:TagContainer = TagContainer.new()

var description setget, get_description
var icon:Texture setget, get_icon
var shell setget, get_shell

var name_func:FuncRef
var icon_func:FuncRef
var desc_func:FuncRef
var shell_func:FuncRef

var blackboard = {}

func _to_string():
	if name_func:
		var return_string = name_func.call_func()
		if return_string:
			return return_string


func get_icon() -> Texture:
	if icon_func:
		var return_icon = icon_func.call_func()
		if return_icon:
			return return_icon
	return null


func get_description() -> String:
	if desc_func:
		var return_string = desc_func.call_func()
		if return_string:
			return return_string
	return ""


func get_shell():
	if shell_func:
		return shell_func.call_func()
	return null


# Called when the node enters the scene tree for the first time.
func _ready():
	if blueprint_id:
		add_to_group("Persist")
	for child in get_children():
		if child.has_method("connect_to_blueprint"):
			child.connect_to_blueprint(self)


func get_all_datablocks_of_type(type:String) -> Array:
	var return_array = []
	for child in get_children():
		if child is Datablock and child.datablock_type_id == type:
			return_array.append(child)
	return return_array
			

func spawn_shell(shell_datablock_name:String = ""):
	var s:ShellDatablock
	if shell_datablock_name:
		s = get_node(shell_datablock_name)
	if not s and has_active_db("ShellDatablock"):
		s = get_active_db("ShellDatablock")
	else:
		return null
	return s._spawn_shell()

func set_active_db(datablock_type_id:String, datablock_path:String):
	bb_set(datablock_type_id, datablock_path, "active_db")


func has_active_db(type:String) -> bool:
	return bb_has(type, "active_db")


func get_active_db(datablock_type_id:String) -> Node:
	return get_node(get_active_db_path(datablock_type_id))


func get_active_db_path(datablock_type_id:String) -> String:
	if has_active_db(datablock_type_id):
		return bb_get(datablock_type_id, "active_db")
	return ""
# Attribute Functions-----------------------------------------------------------
func _on_attribute_value_changed(attr_set, id, old_value, new_value):
	pass


func on_actor_name_change(old_name, new_name):
	pass


func add_gameplay_effect(new_effect:GameplayEffect, source, description = "", additional_info = {}):
	var attr_set:AttributeSet = get_active_db("AttributeSet")
	if not attr_set:
		return null
	return attr_set.add_gameplay_effect(new_effect, source, description, additional_info)


func get_attr(attr_id:String, tag_filter = PoolStringArray()):
	var attr_set:AttributeSet = get_active_db("AttributeSet")
	if not attr_set:
		return null
	return attr_set.get_attr_value(attr_id, tag_filter)


func get_attr_base(attr_id:String):
	var attr_set:AttributeSet = get_active_db("AttributeSet")
	if not attr_set:
		return null
	return attr_set.get_attr_base(attr_id)


func get_attr_spec(attr_id:String):
	var attr_set:AttributeSet = get_active_db("AttributeSet")
	if not attr_set:
		return null
	
	if attr_set.attributes.has(attr_id):
		return attr_set.attributes[attr_id]
	else:
		return null

# Blackboard Functions *********************************************************
func bb_set(key, value, blackboard_name = 'default'):
	if not blackboard.has(blackboard_name):
		blackboard[blackboard_name] = {}

	blackboard[blackboard_name][key] = value


func bb_get(key, blackboard_name = 'default'):
	if bb_has(key, blackboard_name):
		return blackboard[blackboard_name][key]


func bb_has(key, blackboard_name = 'default'):
	return blackboard.has(blackboard_name) and blackboard[blackboard_name].has(key) and blackboard[blackboard_name][key] != null


func bb_erase(key, blackboard_name = 'default'):
	if blackboard.has(blackboard_name):
		 blackboard[blackboard_name][key] = null


# Data Functions ***************************************************************
func _save() -> Dictionary:
	var save_dict = {
		"script":get_script().resource_path,
		"name":name,
		"parent":get_parent().get_path(),
		"tags":tagContainer.tags,
		"blackboard":blackboard,
		"children":{},
	}
	for child in get_children():
		if child.has_method("_save"):
			save_dict["children"][child.name] = child.save()
	return save_dict

func _load(load_dict:Dictionary) -> bool:
	name = load_dict["name"]
	get_node(load_dict["parent"]).add_child(self)
	tagContainer.tags = load_dict["tags"]
	blackboard = load_dict["blackboard"]
	
	for c_name in load_dict["children"].keys():
		var c_dict = load_dict["children"][c_name]
		var script:Script = load(c_dict["script"])
		var c:Node = script.new()
		if c:
			add_child(c)
			c._load(c_dict)
			if c.has_method("connect_to_blueprint"):
				c.connect_to_blueprint(self)
	return true
