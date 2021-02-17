class_name ConditionSpec
extends Reference

signal condition_checked(condition, response)

var source:Blueprint
var target:Blueprint
var additional_data:Dictionary
var condition:Condition

func _init(_condition, _source, _target, _add_data = {}):
	condition = _condition
	source = _source
	target = _target
	additional_data = _add_data
	var cond_func = condition.function
	if not cond_func.connect_spec(self):
		print("%s CondSpec: ERROR, unable to connect to event.")

func signal_condition(_arg1 = null, _arg2 = null, _arg3 = null, _arg4 = null, _arg5 = null, _arg6 = null, _arg7 = null, _arg8 = null):
	emit_signal("condition_checked", condition.check_condition(source, target, additional_data))

# Data Functions ***************************************************************
func _save() -> Dictionary:
	var save_dict = {
		"condition":condition.resource_path,
		"source":source.get_path(),
		"target":target.get_path(),
		"additional_data":additional_data,
	}
	return save_dict
