class_name PlayerController extends Node

var input_enabled := false

signal attack
signal interact
signal toggle_inventory_ui
signal reload
signal set_active_slot(idx: int)
signal test_input(type: String)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		interact.emit()
		
	elif event.is_action_pressed("ui_inventory"):
		toggle_inventory_ui.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		attack.emit()
	elif event.is_action_pressed("reload"):
		reload.emit()
	elif event.is_action_pressed("weapon_1"):
		set_active_slot.emit(0)
	elif event.is_action_pressed("weapon_2"):
		set_active_slot.emit(1)
	elif event.is_action_pressed("test_add_item"):
		test_input.emit("test_add_item")
	elif event.is_action_pressed("test_remove_item"):
		test_input.emit("test_remove_item")
	elif event.is_action_pressed("test_damage"):
		test_input.emit("test_damage")
	elif event.is_action_pressed("test_heal"):
		test_input.emit("test_heal")
	
