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
var conditionTimer:Timer
var turn_duration_remaining:int

var created_modifiers: = []

var source:Blueprint
var target:Blueprint

var effect_source_description:String
var additional_data: = {}

var stack_list: = {}

var cached_duration: = 0.0
var cached_period: = 0.0
var cached_turn_duration:= 0

var effect_enabled = true setget set_effect_enabled, get_effect_enabled

var tags_applied = false

var premature_expiration = true

var tagContainer:TagContainer setget set_tag_container, get_tag_container

var event_condition_list = []

func _init(attr_set):
	target = attr_set.blueprint
	if target.get("tagContainer"):
		self.tagContainer = target.tagContainer
	connect("modifiers_applied", attr_set, "on_modifiers_applied")
	connect("effect_activate", attr_set, "on_effect_activate")
	connect("effect_deactivate", attr_set, "on_effect_deactivate")
	connect("effect_end", attr_set, "on_effect_end")
	
	periodTimer = Timer.new()
	periodTimer.connect("timeout", self, "_on_period_timeout")
	add_child(periodTimer)
	
	durationTimer = Timer.new()
	durationTimer.connect("timeout", self, "_on_duration_timeout")
	add_child(durationTimer)

	conditionTimer = Timer.new()
	conditionTimer.connect("timeout", self, "_on_condition_timeout")
	add_child(conditionTimer)


func set_effect_info(_source:Node, _effect_resource:GameplayEffect, _source_description = "", _add_data = {}):
	# Call either this or _load()
	gameplay_effect = _effect_resource
	source = _source
	additional_data = _add_data
	effect_source_description = _source_description
	if not check_application_conditions():
		queue_free()
		return
	for cond in gameplay_effect.condition_ongoing:
		if cond is Condition:
			if cond.function.event_run:
				var cond_spec:= ConditionSpec.new(cond, source, target, additional_data)
				cond_spec.connect("condition_checked", self, "on_ongoing_condition_checked")
				event_condition_list.append(cond_spec)
	activate_effect()


func activate_effect():
	var apply_chance = gameplay_effect.get_apply_chance(source, target, additional_data)
	if apply_chance > randf():
		queue_free()
		return

	if tagContainer and effect_enabled:
		add_tags()
	
	var attr_set = target.get_active_db("AttributeSet")
	var remove_self = false
	for tag in gameplay_effect.remove_effects_with_tags:
		var effect_array = attr_set.get_effects_with_tag(tag)
		for effect in effect_array:
			if effect == self:
				remove_self = true
				continue
			effect.queue_free()
	if remove_self:
		queue_free()
		return
	
	if gameplay_effect.duration_type == GameplayEffect.DurationType.DURATION || gameplay_effect.duration_type == GameplayEffect.DurationType.INFINITE:
		if gameplay_effect.period_time > 0:
			if gameplay_effect.period_execute_modifiers_on_application:
				send_modifiers()
			periodTimer.start(get_period_magnitude())
		else:
			send_modifiers()
		if gameplay_effect.duration_type == GameplayEffect.DurationType.DURATION:
			durationTimer.start(get_duration_magnitude())
		
		if gameplay_effect.turn_duration_magnitude and \
				gameplay_effect.turn_duration_signal_group and \
				gameplay_effect.turn_duration_signal:
			var turn_group = get_tree().get_nodes_in_group(gameplay_effect.turn_duration_signal_group)
			for node in turn_group:
				node.connect(gameplay_effect.turn_duration_signal, self, "_on_turn_pass")
			turn_duration_remaining = get_turn_duration_magnitude()
	else:	#Instant
#		print("Applying instant effect %s" % gameplay_effect.effect_ID)
		send_modifiers()
		premature_expiration = false
		queue_free()
	
	if gameplay_effect.check_conditions_timer > 0:
		conditionTimer.start(gameplay_effect.check_conditions_timer)
	emit_signal("effect_start", self)


func check_application_conditions() -> bool:
	if gameplay_effect.condition_application.empty():
		return true
	var requirement_met = true
	for cond in gameplay_effect.condition_application:
		if cond is Condition:
			if not cond.check_condition(source, target, additional_data):
				return false
	return true


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
			for eff in gameplay_effect.expiration_effects_routine.keys():
				var desc = effect_source_description
				if eff.additional_data.has("effect_description"):
					desc = eff.additional_data["effect_description"]
				apply_other_effect(eff, source, target, desc, eff.additional_data)
			clear_stack_list()
			premature_expiration = false
			queue_free()
		GameplayEffect.StackExpirationPolicy.REMOVE_SINGLE_STACK_AND_REFRESH_DURATION:
			remove_stack()
			if gameplay_effect.duration_type == GameplayEffect.DurationType.DURATION:
					durationTimer.start(get_duration_magnitude())
			if gameplay_effect.turn_duration_magnitude and \
					gameplay_effect.turn_duration_signal_group and \
					gameplay_effect.turn_duration_signal:
				turn_duration_remaining = get_turn_duration_magnitude()
			
		GameplayEffect.StackExpirationPolicy.REFRESH_DURATION:
			if gameplay_effect.duration_type == GameplayEffect.DurationType.DURATION:
					durationTimer.start(get_duration_magnitude())
			if gameplay_effect.turn_duration_magnitude and \
						gameplay_effect.turn_duration_signal_group and \
						gameplay_effect.turn_duration_signal:
				turn_duration_remaining = get_turn_duration_magnitude()


func _on_condition_timeout():
	self.effect_enabled = check_ongoing_conditions()


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


func remove_stack():
	stack_list.keys()[0] -= 1
	if stack_list.keys()[0] <= 0:
		stack_list.keys().remove(0)
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
			var desc = effect_source_description
			if eff.additional_data.has("effect_description"):
				desc = eff.additional_data["effect_description"]
			apply_other_effect(eff, source, target, desc, eff.additional_data)
	remove_tags()
	self.effect_enabled = false
	destroy_effects()
	emit_signal("effect_end", self)
	.queue_free()


func check_ongoing_conditions() -> bool:
	if gameplay_effect.condition_ongoing.empty():
		return true
	var requirements_met = true
	for cond in gameplay_effect.condition_ongoing:
		if cond is Condition:
			if not cond.function.event_run:
				if not cond.check_condition(source, target, additional_data):
					return false
	return true


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
	if gameplay_effect.duration_type == GameplayEffect.DurationType.INSTANT:
		return
	var search_source = effect_spec.source.name
	if stack_list.has(search_source):
		if gameplay_effect.duration_type == GameplayEffect.StackingType.AGGREGATE_BY_SOURCE:
			if stack_list[search_source] < gameplay_effect.stack_limit_count:
				stack_list[search_source] += 1
				apply_stacking_policies()
			else:
				if not gameplay_effect.overflow_effects.empty():
					for eff in gameplay_effect.overflow_effects:
						var desc = effect_source_description
						if eff.additional_data.has("effect_description"):
							desc = eff.additional_data["effect_description"]
						apply_other_effect(eff, effect_spec.source, effect_spec.target, desc, eff.additional_data)
				if not gameplay_effect.overflow_deny_application:
					apply_stacking_policies()
				elif gameplay_effect.overflow_clear_stack:
					clear_stack_list()
				emit_signal("overflow_triggered", self)
		else:
			if get_num_stacks() < gameplay_effect.stack_limit_count:
				stack_list[search_source] += 1
				apply_stacking_policies()
			else:
				if not gameplay_effect.overflow_effects.empty():
					for eff in gameplay_effect.overflow_effects:
						var desc = effect_source_description
						if eff.additional_data.has("effect_description"):
							desc = eff.additional_data["effect_description"]
						apply_other_effect(eff, effect_spec.source, effect_spec.target, desc, eff.additional_data)
				if not gameplay_effect.overflow_deny_application:
					apply_stacking_policies()
				elif gameplay_effect.overflow_clear_stack:
					clear_stack_list()
				emit_signal("overflow_triggered", self)
	else:
		stack_list[search_source] = 1
		apply_stacking_policies()


func apply_other_effect(_new_effect:GameplayEffect, _source: Blueprint, _target:Blueprint, _source_description = "", _additional_info = {}):
	_target.add_gameplay_effect(_new_effect, _source, _source_description, _additional_info)


func _on_turn_pass():
	turn_duration_remaining -= 1
	if turn_duration_remaining <= 0:
		if not gameplay_effect.duration_turn_is_premature:
			premature_expiration = false
		_on_duration_timeout()
	self.effect_enabled = check_ongoing_conditions()


func get_num_stacks() -> int:
	var sum:int = 0
	for stack_source in stack_list.keys():
		sum += stack_list[stack_source].size()
	return sum

# Data Functions ***************************************************************
func _save() -> Dictionary:
	var save_dict = {
		"script":get_script().resource_path,
		"effect_resource":gameplay_effect.resource_path,
		
		"period_time_left":periodTimer.time_left,
		"period_time_paused":periodTimer.paused,
		
		"duration_time_left":durationTimer.time_left,
		"duration_time_paused":durationTimer.paused,
		
		"turn_duration_remaining":turn_duration_remaining,
		
		"source_path":source.get_path(),
		"effect_source_description":effect_source_description,
		"additional_data":additional_data,
		"stack_list":stack_list,
		"event_conditions":[],
		"connections":get_incoming_connections(),
	}
	for cond_spec in event_condition_list:
		save_dict["event_conditions"].append(cond_spec._save())
	return save_dict


func _load(load_dict:Dictionary) -> bool:
	gameplay_effect = load(load_dict["effect_resource"])
	
	periodTimer.start(load_dict["period_time_left"])
	periodTimer.paused = load_dict["period_time_paused"]
	
	durationTimer.start(load_dict["duration_time_left"])
	durationTimer.paused = load_dict["duration_time_paused"]
	
	source = get_node(load_dict["source_path"])
	effect_source_description = load_dict["effect_source_description"]
	additional_data = load_dict["additional_data"]
	stack_list = load_dict["stack_list"]
	turn_duration_remaining = load_dict["turn_duration_remaining"]
	
	for connect_dict in load_dict["connections"]:
		get_node(connect_dict["source"]).connect(connect_dict["signal_name"], self, connect_dict["method_name"])
	
	for cond_spec_dict in load_dict["event_conditions"]:
		var cond_spec:=ConditionSpec.new(
				load(cond_spec_dict["condition"]),\
				get_node(cond_spec_dict["source"]),\
				get_node(cond_spec_dict["target"]),\
				cond_spec_dict["additional_data"]
		)
		cond_spec.connect("condition_checked", self, "on_ongoing_condition_checked")
		event_condition_list.append(cond_spec)
	activate_effect()
	return true


func on_ongoing_condition_checked(condition, response):
	self.effect_enabled = response
