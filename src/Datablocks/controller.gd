class_name Controller
extends State

export(bool) var player_controlled
var shell_db:ShellDatablock

func _ready():
	shell_db = _state_machine.get_parent()
