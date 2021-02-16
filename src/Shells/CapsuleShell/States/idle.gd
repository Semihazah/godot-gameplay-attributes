extends "res://src/Shells/shell_state.gd"

func unhandled_input(event: InputEvent) -> void:
	_parent.unhandled_input(event)


func physics_process(delta: float) -> void:
	_parent.physics_process(delta)
	if shell.move_target != Vector3.ZERO:
		_state_machine.transition_to("Move/MoveTo")
	elif shell.input_direction != Vector3.ZERO:
		_state_machine.transition_to("Move/MoveInput")


func enter(_msg: Dictionary = {}) -> void:
	_parent.velocity = Vector3.ZERO
	_parent.direction = Vector3.ZERO
	_parent.enter()


func exit() -> void:
	_parent.exit()
