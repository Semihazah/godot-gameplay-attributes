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
var tagContainer:TagContainer
var attributes = {}

func _connect_to_blueprint(new_blueprint):
	._connect_to_blueprint(new_blueprint)
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


func add_gameplay_effect(new_effect:GameplayEffect, source, description = "", additional_info = {}):
#	print("Adding gameplay effect %s" % new_effect.effect_ID)
	var new_spec: = GameplayEffectSpec.new(source, blueprint, new_effect, description, additional_info)
	add_gameplay_effect_spec(new_spec)
	return new_spec
	

func add_gameplay_effect_spec(new_effect:GameplayEffectSpec):
	var effect_resource = new_effect.gameplay_effect
	if effect_resource.stacking_type == GameplayEffect.StackingType.NONE:
#			print("AttributeSet: New effect recieved!")
			new_effect.connect("modifiers_applied", self, "on_modifiers_applied")
			new_effect.connect("effect_activate", self, "on_effect_activate")
			new_effect.connect("effect_deactivate", self, "on_effect_deactivate")
			new_effect.connect("effect_end", self, "on_effect_end")
			add_child(new_effect)
	else:
		var current_effect: = find_effect_with_id(effect_resource.effect_ID)
		if current_effect:
			current_effect.add_stack(new_effect)
		else:
			new_effect.connect("modifiers_applied", self, "on_modifiers_applied")
			new_effect.connect("effect_activate", self, "on_effect_activate")
			new_effect.connect("effect_deactivate", self, "on_effect_deactivate")
			new_effect.connect("effect_end", self, "on_effect_end")
			add_child(new_effect)
	emit_signal("effect_added", self, new_effect)
#	MainLog.add_line("Effect added: %s" % effect_resource.effect_name)


func apply_other_effect(source_data: Node, target_data:Node, effect_resource:GameplayEffect, source_description:String = "", add_data = {}):
	if target_data.get("attributeSet"):
		var new_spec: = GameplayEffectSpec.new(source_data, target_data, effect_resource, source_description, add_data)
		target_data.attributeSet.add_new_effect(new_spec)


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
