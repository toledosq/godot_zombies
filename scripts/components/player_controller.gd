class_name PlayerController extends Node

var input_enabled := false
var action_delay_active := false

signal attack
signal interact
signal toggle_inventory_ui()
signal reload
signal set_active_slot(idx: int)
signal test_input(type: String)
signal crouch_hold_changed(is_held: bool)
signal crouch_toggle_pressed
signal sprint_changed(is_sprinting: bool)
signal cancel_action
signal aim_changed(is_aiming: bool)

func _input(event: InputEvent) -> void:
	# Cancel action always works during action delay
	if event.is_action_pressed("cancel_action") and action_delay_active:
		print("PlayerController: Cancel action pressed")
		cancel_action.emit()
		return
	
	# Block most inputs during action delay
	if action_delay_active:
		return
	
	if event.is_action_pressed("interact"):
		interact.emit()
		
	elif event.is_action_pressed("ui_inventory"):
		toggle_inventory_ui.emit()

func _unhandled_input(event: InputEvent) -> void:
	# Block inputs during action delay (except movement which is handled in Player)
	if action_delay_active:
		return
		
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
	elif event.is_action_pressed("test_action_delay_short"):
		test_input.emit("test_action_delay_short")
	elif event.is_action_pressed("test_action_delay_long"):
		test_input.emit("test_action_delay_long")
	elif event.is_action_pressed("crouch_toggle"):
		crouch_toggle_pressed.emit()
	elif event.is_action_pressed("crouch_hold"):
		print("PlayerController: Crouch Hold active")
		crouch_hold_changed.emit(true)
	elif event.is_action_released("crouch_hold"):
		print("PlayerController: Crouch Hold released")
		crouch_hold_changed.emit(false)
	elif event.is_action_pressed("sprint"):
		print("PlayerController: Sprint started")
		sprint_changed.emit(true)
	elif event.is_action_released("sprint"):
		print("PlayerController: Sprint ended")
		sprint_changed.emit(false)
	elif event.is_action_pressed("aim"):
		print("PlayerController: Aim started")
		aim_changed.emit(true)
	elif event.is_action_released("aim"):
		print("PlayerController: Aim ended")
		aim_changed.emit(false)


func set_action_delay_active(active: bool) -> void:
	print("PlayerController: Action delay active = %s" % active)
	action_delay_active = active
