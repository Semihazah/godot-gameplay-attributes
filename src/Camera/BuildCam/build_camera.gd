extends Spatial


const MOVE_MARGIN = 20
const MOVE_SPEED = 30

const ray_length = 1000

onready var cam = $Camera

func calc_move(m_pos, delta):
	var v_size = get_viewport().size
	var move_vec = Vector3()
	if m_pos.x < MOVE_MARGIN:
		move_vec.x -= 1
	if m_pos.y < MOVE_MARGIN:
		move_vec.z -= 1
	if m_pos.x > v_size.x - MOVE_MARGIN:
		move_vec.x += 1
	if m_pos.y > v_size.y - MOVE_MARGIN:
		move_vec.z += 1
	move_vec.rotated(Vector3.UP, rotation_degrees.y)
	global_translate(move_vec * delta * MOVE_SPEED)


func _process(delta):
	var m_pos = get_viewport().get_mouse_position()
	calc_move(m_pos, delta)
