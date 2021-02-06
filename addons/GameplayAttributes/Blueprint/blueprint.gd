class_name Blueprint
extends Node

var Datablock = load("res://addons/GameplayAttributes/Blueprint/datablock.gd")

export(String) var blueprint_id
export(PoolStringArray) var default_tags

var tagContainer:TagContainer = TagContainer.new()
var active_datablocks = {}

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
	if not s and active_datablocks.has("ShellDatablock"):
		s = active_datablocks["ShellDatablock"]
	else:
		return null
	return s._spawn_shell()
# Attribute Functions-----------------------------------------------------------
func _on_attribute_value_changed(attr_set, id, old_value, new_value):
	pass


func on_actor_name_change(old_name, new_name):
	pass


func add_gameplay_effect(new_effect:GameplayEffect, source, description = "", additional_info = {}):
	if not active_datablocks.has("AttributeSet"):
		return null
	var attr_set:AttributeSet = active_datablocks["AttributeSet"]
	if not attr_set:
		return null
	return attr_set.add_gameplay_effect(new_effect, source, description, additional_info)


func get_attr(attr_id:String, tag_filter = PoolStringArray()):
	if not active_datablocks.has("AttributeSet"):
		return null
	var attr_set:AttributeSet = active_datablocks["AttributeSet"]
	if not attr_set:
		return null
	return attr_set.get_attr_value(attr_id, tag_filter)


func get_attr_base(attr_id:String):
	if not active_datablocks.has("AttributeSet"):
		return null
	var attr_set:AttributeSet = active_datablocks["AttributeSet"]
	if not attr_set:
		return null
	return attr_set.get_attr_base(attr_id)


func get_attr_spec(attr_id:String):
	if not active_datablocks.has("AttributeSet"):
		return null
	var attr_set:AttributeSet = active_datablocks["AttributeSet"]
	if not attr_set:
		return null
	
	if attr_set.attributes.has(attr_id):
		return attr_set.attributes[attr_id]
	else:
		return null

# Blackboard Functions *********************************************************
func set(key, value, blackboard_name = 'default'):
	if not blackboard.has(blackboard_name):
		blackboard[blackboard_name] = {}

	blackboard[blackboard_name][key] = value


func get(key, blackboard_name = 'default'):
	if has(key, blackboard_name):
		return blackboard[blackboard_name][key]


func has(key, blackboard_name = 'default'):
	return blackboard.has(blackboard_name) and blackboard[blackboard_name].has(key) and blackboard[blackboard_name][key] != null


func erase(key, blackboard_name = 'default'):
	if blackboard.has(blackboard_name):
		 blackboard[blackboard_name][key] = null
