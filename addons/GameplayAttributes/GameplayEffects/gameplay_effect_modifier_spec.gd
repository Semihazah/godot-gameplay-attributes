extends Reference
class_name GameplayEffectModifierSpec

var gameplay_effect_modifier:GameplayEffectModifier
var gameplay_effect_spec
var source:Node
var target:Node
var additional_data:= {}

func _init(effect_modifier:GameplayEffectModifier, effect_spec):
	gameplay_effect_modifier = effect_modifier
	gameplay_effect_spec = effect_spec

var effect_enabled: = true setget set_effect_enabled, get_effect_enabled
func set_effect_enabled(is_enabled:bool):
	effect_enabled = is_enabled
func get_effect_enabled():
	return effect_enabled


var spec_enabled: = true setget , get_spec_enabled
func get_spec_enabled():
	return spec_enabled


var affects_base: = false setget set_affects_base, get_affects_base
func set_affects_base(affects):
	affects_base = affects
func get_affects_base():
	return affects_base


func get_operation_type():
	return gameplay_effect_modifier.modifier_operation


var queue_delete: = false setget set_queue_delete, get_queue_delete
func set_queue_delete(queue_for_deletion:bool):
	queue_delete = queue_for_deletion
func get_queue_delete():
	return queue_delete


func get_is_enabled():
	return self.effect_enabled and self.spec_enabled

func get_magnitude():
	return gameplay_effect_modifier.get_magnitude(source, target, additional_data)
