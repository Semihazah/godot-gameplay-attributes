extends BehaviorTree

class_name BehaviorTreeRoot, "../icons/tree.svg"
enum { SUCCESS, FAILURE, RUNNING }

const Blackboard = preload("../blackboard.gd")

export (bool) var enabled = true setget set_enabled
var actor
onready var blackboard: = Blackboard.new()

func _ready():
	if self.get_child_count() != 1:
		print("Behavior Tree error: Root should have one child")
		disable()
		return



func _process(delta):
	if not enabled:
		return

	blackboard.set("delta", delta)

	self.get_child(0).tick(actor, blackboard)


func _run_ai():
	if get_parent().has_method("get_ai_target"):
		actor = get_parent().get_ai_target()
#		print(actor)
	else:
		print("Behavior Tree error: No target specified")
		disable()
		return []
	var failsafe = 100
	var result = RUNNING
	while result == RUNNING:
		result = self.get_child(0).tick(actor, blackboard)
		failsafe -= 1
		if failsafe <= 0:
			break
	if result == SUCCESS:
#		print("AI: Success!")
		var return_array = [
			blackboard.get("selected_command"),
			blackboard.get("selected_targets")
		]
		blackboard.erase("selected_command")
		blackboard.erase("selected_targets")
		return return_array
	else:
		blackboard.erase("selected_command")
		blackboard.erase("selected_targets")
#		print("AI: Failure...")
		return []


func enable():
	self.enabled = true


func disable():
	self.enabled = false

func set_enabled(e:bool):
	enabled = e
	set_process(e)
