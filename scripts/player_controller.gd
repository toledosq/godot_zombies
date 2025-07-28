class_name PlayerController extends Node

var input_enabled := false

signal interact
signal toggle_inventory_ui
signal test_input(type: String)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		interact.emit()
		
	elif event.is_action_pressed("ui_inventory"):
		toggle_inventory_ui.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("test_add_item"):
		test_input.emit("test_add_item")
	elif event.is_action_pressed("test_remove_item"):
		test_input.emit("test_remove_item")
	elif event.is_action_pressed("test_damage"):
		test_input.emit("test_damage")
	elif event.is_action_pressed("test_heal"):
		test_input.emit("test_heal")
