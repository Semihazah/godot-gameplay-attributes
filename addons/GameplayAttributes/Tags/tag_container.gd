class_name TagContainer
extends Reference

signal tag_added(new_tag)
signal tag_removed(removed_tag)
signal tag_stack_removed(removed_tag, num_stacks_left)

var tags = {}

func add_tag(new_tag:String):
	if new_tag:
		if tags.has(new_tag):
			tags[new_tag] += 1
		else:
			tags[new_tag] = 1
#		print("TagContainer: adding tag %s, stacks = %s" % [new_tag, tags[new_tag]])
		emit_signal("tag_added", new_tag)


func remove_tag(tag_to_remove:String):
	if tag_to_remove && tags.has(tag_to_remove):
		tags[tag_to_remove] -= 1
		if tags[tag_to_remove] <= 0:
			tags.erase(tag_to_remove)
			emit_signal("tag_removed", tag_to_remove)
			emit_signal("tag_stack_removed", tag_to_remove, 0)
#			print("remove tag %s, stacks = %s", [tag_to_remove, 0])
			
		else:
			emit_signal("tag_stack_removed", tag_to_remove, tags[tag_to_remove])
#			print("remove tag %s, stacks = %s", [tag_to_remove, tags[tag_to_remove]])
			


func has_tag(search_tag:String, exact_tag:bool) -> bool:
	return get_first_matching_tag(search_tag, exact_tag) != ""


func get_first_matching_tag(search_tag:String, exact_tag:bool) -> String:
	if exact_tag:
		if tags.has(search_tag):
			return search_tag
		else:
			return ""
		
	var search_tag_list = search_tag.split(".")
	for tag in tags.keys():
		var tag_list = tag.split(".")
		var valid = true
		for index in search_tag_list.size():
			if search_tag_list[index] != tag_list[index]:
				valid = false
				break
		if valid:
			return tag
	return ""


func get_matching_tags(search_tag:String, exact_tag:bool = true) -> Array:
	if exact_tag:
		if tags.has(search_tag):
			return [search_tag]
		else:
			return []
	
	var return_array: = []
	var search_tag_list: = search_tag.split(".")
	for tag in tags.keys():
		var tag_list = tag.split(".")
		var valid = true
		for index in search_tag_list.size():
			if search_tag_list[index] != tag_list[index]:
				valid = false
				break
		if valid:
			return_array.append(tag)
	return return_array
