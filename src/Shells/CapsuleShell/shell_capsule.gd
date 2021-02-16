extends KinematicBody

signal task_completed(task_name, success, msg)

onready var stateMachine = $StateMachine

var nav_ref:Navigation
var input_direction:Vector3
var move_target:Vector3

func move_to_pos(pos, move_range = -1):
	$StateMachine.transition_to("Move/MoveTo", {target = pos, target_range = move_range})
