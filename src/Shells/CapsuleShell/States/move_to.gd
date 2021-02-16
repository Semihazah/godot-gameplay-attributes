extends "res://src/Shells/shell_state.gd"

var path:PoolVector3Array
var path_index = 0
var target_range:float

func enter(msg := {}) -> void:
#	print("%s: Entering state" % name)
	path = PoolVector3Array()
	path_index = 0
	if msg.has("target"):
		path = shell.nav_ref.get_simple_path(shell.global_transform.origin, msg["target"])
	elif shell.move_target:
		path = shell.nav_ref.get_simple_path(shell.global_transform.origin, shell.move_target)
#		print("Target pos = %s, path = %s" % [msg["target_pos"], path])
	else:
		_state_machine.transition_to("Move/Idle")
	if msg.has("target_range") and msg["target_range"] > 0:
		target_range = msg["target_range"]
	else:
		target_range = 1.0


func exit() -> void:
#	print("%s: Exiting State" % name)
	target_range = 0
	path = PoolVector3Array()

func physics_process(_delta):
#	print("Moving...")
	var direction: = Vector3()
	if path_index < path.size():
		direction = (path[path_index] - shell.global_transform.origin)
		if path_index == path.size() - 1 and direction.length() <= target_range:
#			print("Target reached")
			_state_machine.transition_to("Move/Idle")
			if shell.has_signal("task_completed"):
#				print("%s: Returning from state" % name)
				shell.emit_signal("task_completed", "move_to_pos", true, {})
#				_state_machine.transition_to("Idle")
			return
		elif direction.length() < target_range:
			path_index += 1
	_parent.direction = direction
	_parent.physics_process(_delta)
	
