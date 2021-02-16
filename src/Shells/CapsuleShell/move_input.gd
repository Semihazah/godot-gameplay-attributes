extends "res://src/Shells/shell_state.gd"


func physics_process(_delta):
	var dir = shell.input_direction
	_parent.direction = dir
	_parent.physics_process(_delta)
	if not dir:
		_state_machine.transition_to("Move/Idle")
		
