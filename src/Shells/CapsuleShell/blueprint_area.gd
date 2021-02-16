extends Area


export(NodePath) var shell_path
var blueprint:Blueprint
var shell:KinematicBody
func _ready():
	shell = get_node(shell_path)
	if "blueprint" in shell:
		blueprint = shell.blueprint
