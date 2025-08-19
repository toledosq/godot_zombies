class_name GlobalInputManager extends Node

signal ui_cancel_requested

func _ready() -> void:
	# Receive input even when tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		print("GlobalInputManager: ui_cancel pressed")
		ui_cancel_requested.emit()
