extends "res://src/Shells/shell_state.gd"


export(float) var move_speed = 10.0
export(float) var max_speed = 12.0
export(float) var gravity = -9.8
export(float) var rotation_speed = 10
var velocity: = Vector3.ZERO
var direction: = Vector3.ZERO



func physics_process(_delta):
	if direction.length() > 1:
		direction = direction.normalized()
	var dir_y_zero:Vector3 = Vector3(direction.x, 0, direction.z)
	if dir_y_zero != Vector3.ZERO:
		var target_direction:Transform = shell.transform.looking_at(shell.global_transform.origin\
				+ Vector3(direction.x, 0, direction.z), Vector3.UP)
		shell.transform = shell.transform.interpolate_with(target_direction, rotation_speed * _delta)
		
	velocity = calculate_velocity(velocity, direction, _delta)
	velocity = shell.move_and_slide(velocity, Vector3.UP)

func calculate_velocity(
		velocity_current: Vector3,
		move_direction: Vector3,
		delta: float
	) -> Vector3:
		var velocity_new:Vector3 = move_direction * move_speed
		if velocity_new.length() > max_speed:
			velocity_new = velocity_new.normalized() * max_speed
		velocity_new.y = velocity_current.y + gravity * delta

		return velocity_new
