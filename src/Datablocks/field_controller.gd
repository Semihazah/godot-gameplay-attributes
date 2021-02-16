extends Controller

var shellDatablock:ShellDatablock
var shell:KinematicBody

func enter(msg := {}) -> void:
	shellDatablock = shell_db
	shellDatablock.connect("shell_changed", self, "on_shell_changed")
	shell = shellDatablock.shell


func on_shell_changed(_blueprint, _old_shell, new_shell):
	shell = new_shell


func physics_process(_delta):
	if player_controlled:
		var m_pos = get_viewport().get_mouse_position()
		if Input.is_action_just_pressed("field_move_select_pos"):
			var camera = shell.get_viewport().get_camera()
			var ray_result = raycast_from_mouse(camera, m_pos, 1, 1000)
			if ray_result and shell.has_method("move_to_pos"):
	#			print("Sending position to shell!")
				shell.move_to_pos(ray_result.position)
	#		else:
	#			print("No result available: %s" % result)
				
		var dir = get_input_direction()
		if shellDatablock and shellDatablock.shell:
			shellDatablock.shell.input_direction = dir


static func get_input_direction() -> Vector3:
	return Vector3(
			Input.get_action_strength("field_move_r") - Input.get_action_strength("field_move_l"),
			0,
			Input.get_action_strength("field_move_b") - Input.get_action_strength("field_move_f")
		)


func raycast_from_mouse(cam, m_pos, collision_mask, ray_length):
	var ray_start = cam.project_ray_origin(m_pos)
	var ray_end = ray_start + cam.project_ray_normal(m_pos) * ray_length
	var space_state = cam.get_world().direct_space_state
	return space_state.intersect_ray(ray_start, ray_end, [], collision_mask)
	
# Data functions ***************************************************************
#func _save() -> Dictionary:
#	var save_dict = {
#
#	}
#	return save_dict
