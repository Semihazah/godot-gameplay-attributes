extends Spatial

var shell

func _ready():
	shell = $Player.spawn_shell()
	add_child(shell)
	var enemy_shell = $Enemy.spawn_shell()
	add_child(enemy_shell)
	if "nav_ref" in shell:
		shell.nav_ref = $Navigation
		enemy_shell.nav_ref = $Navigation
	else:
		print("Cannot find nav ref var")

#func _on_Ground_input_event(camera, event, click_position, click_normal, shape_idx):
#	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
#		if shell.has_method("move_to_pos"):
#			shell.move_to_pos(click_position)
