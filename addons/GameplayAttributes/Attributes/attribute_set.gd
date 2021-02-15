tool
class_name AttributeSet
extends "res://addons/GameplayAttributes/Blueprint/datablock.gd"


signal effect_ended(attr_set, effect)
signal effect_added(attr_set, new_effect)
signal effect_activated(attr_set, effect)
signal effect_deactivated(attr_set, effect)

signal attribute_added(attr_set, id, new_attribute)
signal attribute_removed(attr_set, id, removed_attribute)

signal attribute_value_changed(attr_set, id, previous_value, new_value)
signal attribute_value_min_reached(attr_set, id, new_value, min_value)
signal attribute_value_max_reached(attr_set, id, new_value, max_value)

export(Array, Resource) var attribute_injectors setget _set_attribute_injectors

onready var AttributeInjector = load("res://addons/GameplayAttributes/AttributeInjectors/attribute_injector.gd")
onready var GameplayEffect = load("res://addons/GameplayAttributes/GameplayEffects/gameplay_effect.gd")

var tagContainer:TagContainer
var attributes = {}

func _connect_to_blueprint(new_blueprint):
	tagContainer = new_blueprint.tagContainer

func _init():
	datablock_type_id = "AttributeSet"

func _ready():
	for attr_inject in attribute_injectors:
		if attr_inject.has_method("inject_attribute"):
			attr_inject.inject_attribute(self)


func get_attr_value(attr_id:String, tag_filter = PoolStringArray()):
	if attributes.has(attr_id):
		if tag_filter.size() > 0:
			return attributes[attr_id].calculate_value(tag_filter)
		return attributes[attr_id]._final_value
	return null


func get_attr_base(attr_id:String):
	if attributes.has(attr_id):
		return attributes[attr_id]._base_value
	return null


func get_attr_spec(attr_id):
	if attributes.has(attr_id):
		return attributes[attr_id]
	return null


func create_attribute_spec(attr:Attribute, starting_value, add_data = {}) -> AttributeSpec:
	var new_attr_spec:AttributeSpec
	if File.new().file_exists(attr.attribute_spec_object):
		new_attr_spec = load(attr.attribute_spec_object).new(attr, starting_value, add_data)
		
	if not new_attr_spec:
		new_attr_spec = AttributeSpec.new(attr, starting_value, add_data)
		
	return new_attr_spec


func add_new_attribute_spec(attr_id, attr_spec:AttributeSpec):
	remove_attribute(attr_id)
	attributes[attr_id] = attr_spec
	attr_spec._add_attribute(self)
	emit_signal("attribute_added", self, attr_id, attr_spec)


func remove_attribute(attr_id):
	if attributes.has(attr_id):
		var old_attr:AttributeSpec = attributes[attr_id]
		if old_attr:
			old_attr._remove_attribute(self)
			attributes.erase(attr_id)
			emit_signal("attribute_removed", self, attr_id, old_attr)
		return old_attr
	return null


func on_attribute_value_changed(attr_id, old_value, new_value):
	emit_signal("attribute_value_changed", self, attr_id, old_value, new_value)


func on_attribute_value_min_reached(attr_id, new_value, min_value):
	emit_signal("attribute_value_max_reached", self, attr_id, new_value, min_value)


func on_attribute_value_max_reached(attr_id, new_value, min_value):
	emit_signal("attribute_value_max_reached", attr_id, new_value, min_value)


func add_attribute(attr_path:String, starting_value, add_data = {}) -> AttributeSpec:
	if File.new().file_exists(attr_path):
		var new_attr:Attribute = load(attr_path)
		if new_attr:
			return add_attribute_file(new_attr, starting_value, add_data)
	return null


func add_attribute_file(attr:Attribute, starting_value:float, add_data = {}):
	if attr:
		var new_spec = create_attribute_spec(attr, starting_value, add_data)
		add_new_attribute_spec(attr.attribute_id, new_spec)
		return new_spec
	return null


func add_gameplay_effect(_new_effect:GameplayEffect, _source:Blueprint, _source_description = "", _additional_info = {}):
#	print("Adding gameplay effect %s" % new_effect.effect_ID)
	var new_spec: = GameplayEffectSpec.new(self)
	new_spec.set_effect_info(_source, _new_effect, _source_description, _additional_info)
	if new_spec:
		add_gameplay_effect_spec(new_spec)
	return new_spec
	

func add_gameplay_effect_spec(new_effect:GameplayEffectSpec):
	var effect_resource = new_effect.gameplay_effect
	if effect_resource.stacking_type == GameplayEffect.StackingType.NONE:
#			print("AttributeSet: New effect recieved!")
			add_child(new_effect)
	else:
		var current_effect: = find_effect_with_id(effect_resource.effect_ID)
		if current_effect:
			current_effect.add_stack(new_effect)
		else:
			add_child(new_effect)
	emit_signal("effect_added", self, new_effect)
#	MainLog.add_line("Effect added: %s" % effect_resource.effect_name)


func find_effect_with_id(id:String) -> GameplayEffectSpec:
	for child in get_children():
		if child is GameplayEffectSpec:
			if child.gameplay_effect.effect_ID == id:
				return child
	return null


func on_modifiers_applied(effect:GameplayEffectSpec, mod_specs:Array):
#	print("Attribute set: modifiers applied: %s" % [mod_specs])
	for spec in mod_specs:
		if spec is GameplayEffectModifierSpec:
			var ge_mod:GameplayEffectModifier = spec.gameplay_effect_modifier
#			print("Applying mod " + ge_mod.attribute_id)
			var attr_id = ge_mod.attribute_id
#			print(attr_id)
			if attributes.has(attr_id):
#				print("Adding mod to attribute ", attr_id)
				var attr:AttributeSpec = attributes[attr_id]
				if spec.affects_base:
					attr.apply_base_modifier(spec)
				elif ge_mod.is_final:
					attr.add_final_modifier(spec)
				else:
					attr.add_raw_modifier(spec)
			else:
				print("Failed to find attribute ID")

func on_effect_end(effect):
	emit_signal("effect_ended", self, effect)


func on_effect_activate(effect):
	emit_signal("effect_activated", self, effect)


func on_effect_deactivate(effect):
	emit_signal("effect_deactivated", self, effect)


func _set_attribute_injectors(new_array:Array):
	attribute_injectors = new_array
	for i in new_array.size():
		var value = new_array[i]
		if value is GDScript:
			value = value.new()
			if value is AttributeInjector:
				attribute_injectors[i] = value
		elif not value is AttributeInjector:
			attribute_injectors[i] == null
			if Engine.editor_hint:
				print("Expected class: AttributeInjector")


# Data Functions ***************************************************************
func _save() -> Dictionary:
	var save_dict = {
		"script":get_script().resource_path,
		"attributes":{},
		"children":{},
	}
	for attr in attributes:
		if attr is AttributeSpec:
			save_dict["attributes"][attr.attribute_data.attribute_id] = attr._save()
	for child in get_children():
		if child.has_method("_save"):
			save_dict["children"][child.name] = child._save()
	return save_dict


func _load(load_dict:Dictionary) -> bool:
	name = load_dict["name"]
	for attr_id in load_dict["attributes"].keys():
		var a_dict = load_dict["attributes"][attr_id]
		var script:Script = load(a_dict["script"])
		var attr:AttributeSpec = script.new()
		if attr:
			attr._add_attribute(self)
			attr._load(a_dict)
			attributes[attr_id] = attr
	
	for c_name in load_dict["children"].keys():
		var c_dict = load_dict["children"][c_name]
		var script:Script = load(c_dict["script"])
		var c = script.new()
		if c is GameplayEffectSpec:
			add_gameplay_effect_spec(c)
			c._load(c_dict)
		elif c is Node:
			add_child(c)
			c._load(c_dict)
	return true
