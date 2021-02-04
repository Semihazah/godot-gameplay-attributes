extends Node
class_name GameplayEffectSpec

signal modifiers_applied(effect, modifiers)

signal effect_start(effect)
signal effect_end(effect)
signal effect_activate(effect)
signal effect_deactivate(effect)

signal stack_added(effect)
signal stack_removed(effect)

signal overflow_triggered(effect)

var gameplay_effect:GameplayEffect

var periodTimer:Timer
var durationTimer:Timer

var created_modifiers:Array

var source:Node
var target:Node

var effect_source_description:String
var additional_data: = {}

var stack_list: = {}

var cached_duration: = 0.0
var cached_period: = 0.0
var cached_turn_duration:= 0
var duration_turns_remaining:int

var effect_enabled = true setget set_effect_enabled, get_effect_enabled

var tags_applied = false

var premature_expiration = true

var tagContainer:TagContainer setget set_tag_container, get_tag_container

func _init(source_data:Node, target_data:Node, effect_resource:GameplayEffect, source_description = "", add_data = {}):
	created_modifiers = []
	gameplay_effect = effect_resource
	source = source_data
	target = target_data
	additional_data = add_data
	if target_data.get("tagContainer"):
		self.tagContainer = target_data.tagContainer
	effect_source_description = source_description


func _ready():
	if tagContainer:
#		print("Found tag container: ", tagContainer)
		check_tags()
		tagContainer.connect("tag_added", self, "on_tag_added")
		tagContainer.connect("tag_removed", self, "on_tag_removed")
		
		if effect_enabled:
			add_tags()
	else:
		if not gameplay_effect.tags_application_require.empty():
			queue_free()
			return
	
#	print("Effect: begining ready function")

	
	if gameplay_effect.duration_type == GameplayEffect.DurationType.DURATION || gameplay_effect.duration_type == GameplayEffect.DurationType.INFINITE:
		periodTimer = Timer.new()
		periodTimer.connect("timeout", self, "_on_period_timeout")
		add_child(periodTimer)
		
		durationTimer = Timer.new()
		durationTimer.connect("timeout", self, "_on_duration_timeout")
		add_child(durationTimer)
		if gameplay_effect.period_time > 0:
			if gameplay_effect.period_execute_modifiers_on_application:
				send_modifiers()
			periodTimer.start(get_period_magnitude())
		else:
			send_modifiers()
		if gameplay_effect.duration_type == GameplayEffect.DurationType.DURATION:
			durationTimer.start(get_duration_magnitude())
		
		if gameplay_effect.turn_duration_magnitude_calculation_type and \
				gameplay_effect.turn_duration_signal_group and \
				gameplay_effect.turn_duration_signal:
			var turn_group = get_tree().get_nodes_in_group(gameplay_effect.turn_duration_signal_group)
			for node in turn_group:
				node.connect(gameplay_effect.turn_duration_signal, self, "_on_turn_pass")
			duration_turns_remaining = get_turn_duration_magnitude()
				
				
	else:	#Instant
#		print("Applying instant effect %s" % gameplay_effect.effect_ID)
		send_modifiers()
		premature_expiration = false
		queue_free()
	

	emit_signal("effect_start", self)
	


func send_modifiers():
#	print("Sending modifiers")
	for mod in gameplay_effect.modifiers:
		if mod is GameplayEffectModifier:
			var new_mod_spec: = create_modifier_spec(mod)
			if !effect_enabled:
				new_mod_spec.effect_enabled = false
			created_modifiers.append(new_mod_spec)
	emit_signal("modifiers_applied", self, created_modifiers)



func _on_period_timeout():
	send_modifiers()


func _on_duration_timeout(): 
	match gameplay_effect.stack_expiration_policy:
		GameplayEffect.StackExpirationPolicy.CLEAR_ENTIRE_STACK:
			for eff in gameplay_effect.expiration_effects_routine:
				apply_other_effect(source, target, eff, eff.effect_source_description, additional_data)
			clear_stack_list()
			premature_expiration = false
			queue_free()
		GameplayEffect.StackExpirationPolicy.REMOVE_SINGLE_STACK_AND_REFRESH_DURATION:
			remove_random_stack()
			if gameplay_effect.duration_type == GameplayEffect.DurationType.DURATION:
					durationTimer.start(get_duration_magnitude())
			if gameplay_effect.turn_duration_magnitude_calculation_type and \
					gameplay_effect.turn_duration_signal_group and \
					gameplay_effect.turn_duration_signal:
				duration_turns_remaining = get_turn_duration_magnitude()
			
		GameplayEffect.StackExpirationPolicy.REFRESH_DURATION:
			if gameplay_effect.duration_type == GameplayEffect.DurationType.DURATION:
					durationTimer.start(get_duration_magnitude())
			if gameplay_effect.turn_duration_magnitude_calculation_type and \
						gameplay_effect.turn_duration_signal_group and \
						gameplay_effect.turn_duration_signal:
				duration_turns_remaining = get_turn_duration_magnitude()


func get_duration_magnitude():
	cached_duration = gameplay_effect.get_duration_magnitude(source, target, additional_data)
	return cached_duration


func get_period_magnitude():
	cached_period = gameplay_effect.get_period_magnitude(source, target, additional_data)
	return cached_period


func get_turn_duration_magnitude():
	cached_turn_duration = gameplay_effect.get_turn_duration_magnitude(source, target, additional_data)
	return cached_turn_duration
	
	
func clear_stack_list():
	if not stack_list.empty():
		stack_list.clear()
		emit_signal("stack_removed", self)


func remove_random_stack():
	var index = randi() % stack_list.keys().size()
	var subindex = randi() % stack_list.keys()[index].size()
	stack_list.keys()[index].remove(subindex)
	if stack_list.keys()[index].empty():
		stack_list.keys().remove(index)
	emit_signal("stack_removed", self)


func set_effect_enabled(enabled:bool):
	if effect_enabled != enabled:
		effect_enabled = enabled
		if enabled:
			for mod in created_modifiers:
				if mod is GameplayEffectModifierSpec:
					mod.effect_enabled = true
			add_tags()
			emit_signal("effect_activate", self)
		else:
			for mod in created_modifiers:
				if mod is GameplayEffectModifierSpec:
					mod.effect_enabled = false
			remove_tags()
			emit_signal("effect_deactivate", self)


func get_effect_enabled():
	return effect_enabled


func destroy_effects():
	for mod in created_modifiers:
		if mod is GameplayEffectModifierSpec:
			mod.queue_delete = true


func queue_free():
#	print("Ending effect")
	if premature_expiration:
		for eff in gameplay_effect.premature_expiration_effect_classes:
			apply_other_effect(source, target, eff, eff.effect_source_description, additional_data)
	remove_tags()
	effect_enabled = false
	destroy_effects()
	emit_signal("effect_end", self)
	.queue_free()


func on_tag_added(tag_added):
#	print("Tag Added!: %s" % tag_added)
	check_tags()


func on_tag_removed(tag_removed):
#	print("Tag Removed: %s" % tag_removed)
	check_tags()


func check_tags():
	if not gameplay_effect.removal_require_tags.empty():
		var require_met = true
		for tag in gameplay_effect.removal_require_tags:
			if not tagContainer.has_tag(tag, true):
				require_met = false
		if require_met:
			queue_free()
			return
			
	if not gameplay_effect.removal_ignore_tags.empty():
		var require_met = true
		for tag in gameplay_effect.removal_ignore_tags:
			if tagContainer.has_tag(tag, true):
				require_met = false
		if require_met:
			queue_free()
			return
	
	var can_continue01 = true
	if not gameplay_effect.ongoing_require_tags.empty():
		for tag in gameplay_effect.ongoing_require_tags:
			if not tagContainer.has_tag(tag, true):
				can_continue01 = false
				break


	var can_continue02 = true
	if not gameplay_effect.ongoing_ignore_tags.empty():
		for tag in gameplay_effect.ongoing_ignore_tags:
			if tagContainer.has_tag(tag, true):
				can_continue02 = false
				break
	
	if not can_continue01 or not can_continue02:
		self.effect_enabled = false
	else:
		self.effect_enabled = true
		



func add_tags():
	if tagContainer:
		for tag in gameplay_effect.granted_tags:
#			print("EffectSpec: adding tag ", tag)
			tagContainer.add_tag(tag)
		tags_applied = true


func remove_tags():
	if tagContainer and tags_applied:
		for tag in gameplay_effect.granted_tags:
			tagContainer.remove_tag(tag)


func set_tag_container(new_container:TagContainer):
	if tagContainer:
		remove_tags()
	tagContainer = new_container


func get_tag_container():
	return tagContainer


func create_modifier_spec(mod:GameplayEffectModifier) -> GameplayEffectModifierSpec:
	var new_mod_spec:GameplayEffectModifierSpec
	if mod.mod_spec_object:
		var new_spec:GameplayEffectModifierSpec = load(mod.mod_spec_object).new(mod, self)
		if new_spec:
			new_mod_spec = new_spec
		
	if not new_mod_spec:
		new_mod_spec = GameplayEffectModifierSpec.new(mod, self)
	new_mod_spec.source = source
	new_mod_spec.target = target
	
	match gameplay_effect.duration_type:
		GameplayEffect.DurationType.INSTANT:
			new_mod_spec.affects_base = true
		GameplayEffect.DurationType.INFINITE:
			if gameplay_effect.period > 0:
				new_mod_spec.affects_base = true
		GameplayEffect.DurationType.DURATION:
			if gameplay_effect.period > 0:
				new_mod_spec.affects_base = true
	new_mod_spec.source
	return new_mod_spec


func apply_stacking_policies():
	if gameplay_effect.stack_duration_refresh_policy == GameplayEffect.StackDurationRefreshPolicy.REFRESH_ON_SUCCESSFUL_APPLICATION:
		durationTimer.start(get_duration_magnitude())
	
	if gameplay_effect.stack_period_reset_policy == GameplayEffect.StackDurationRefreshPolicy.REFRESH_ON_SUCCESSFUL_APPLICATION:
		periodTimer.start(get_period_magnitude())
	
	emit_signal("stack_added", self)


func add_stack(effect_spec:GameplayEffectSpec):
	if gameplay_effect.duration_type != GameplayEffect.DurationType.INSTANT:
		var search_source = effect_spec.source
		if stack_list.has(search_source):
			if gameplay_effect.duration_type == GameplayEffect.StackingType.AGGREGATE_BY_SOURCE:
				if stack_list[search_source].size() < gameplay_effect.stack_limit_count:
					stack_list[search_source].append(effect_spec)
					apply_stacking_policies()
				else:
					if not gameplay_effect.overflow_effects.empty():
						for eff in gameplay_effect.overflow_effects:
							apply_other_effect(effect_spec.source, effect_spec.target, eff, effect_spec.effect_source_description, additional_data)
					if not gameplay_effect.overflow_deny_application:
						apply_stacking_policies()
					elif gameplay_effect.overflow_clear_stack:
						clear_stack_list()
					emit_signal("overflow_triggered", self)
			else:
				if get_num_stacks() < gameplay_effect.stack_limit_count:
					stack_list[search_source].append(effect_spec)
					apply_stacking_policies()
				else:
					if not gameplay_effect.overflow_effects.empty():
						for eff in gameplay_effect.overflow_effects:
							apply_other_effect(effect_spec.source, effect_spec.target, eff, effect_spec.effect_source_description, additional_data)
					if not gameplay_effect.overflow_deny_application:
						apply_stacking_policies()
					elif gameplay_effect.overflow_clear_stack:
						clear_stack_list()
					emit_signal("overflow_triggered", self)
		else:
			stack_list[search_source] = [effect_spec]
			apply_stacking_policies()


func apply_other_effect(source_data: Node, target_data:Node, effect_resource:GameplayEffect, source_description:String = "", add_data = {}):
	if target_data.get("attributeSet"):
		var attr_set = target_data.attributeSet
		attr_set.apply_other_effect(source_data, target_data, effect_resource, source_description, add_data)


func _on_turn_pass():
	duration_turns_remaining -= 1
	if duration_turns_remaining <= 0:
		if not gameplay_effect.duration_turn_is_premature:
			premature_expiration = false
		_on_duration_timeout()


func get_num_stacks() -> int:
	var sum:int = 0
	for stack_source in stack_list.keys():
		sum += stack_list[sum].size()
	return sum