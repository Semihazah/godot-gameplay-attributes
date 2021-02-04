#class_name Shell
# The physical version of a Blueprint that exists in the world.
# May or may not act as a parent or child of the Blueprint.
# Connected through a WorldDatablock to the Blueprint.
# May recieve orders through Commands (Need to decouple).
extends Node

# Interface script. Do not extend.
# Copy functions and variables to new script
signal task_completed(task_id, success, additional_info)

var parent_datablock
func _connect_to_datablock(world_datablock):
	parent_datablock = world_datablock


func _disconnect_from_datablock():
	parent_datablock = null


func get_position():
	return null


func get_ai_target():
	return self


func perform_task(task_name, additional_info = {}):
	return false
