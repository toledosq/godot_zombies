extends Control

signal inventory_opened
signal inventory_closed

@export var slot_count: int = 16
@export var columns: int = 4

@onready var grid_container: GridContainer = $CenterContainer/HBoxContainer/GridContainer


func _ready() -> void:
	visible = false
	_populate_grid()

func _input(event) -> void:
	if event.is_action_pressed("ui_inventory"):
		visible = not visible
		_update_mouse_mode()

func _update_mouse_mode() -> void:
	if visible:
		emit_signal("inventory_opened")
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		emit_signal("inventory_closed")
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

func _populate_grid() -> void:
	# Clear any existing slots
	for child in grid_container.get_children():
		child.queue_free()
		
	for i in range(slot_count):
		var panel = Panel.new()
		panel.custom_minimum_size = Vector2(64, 64)
		grid_container.add_child(panel)

func _set_slot_count(new_count: int) -> void:
	slot_count = new_count
	_populate_grid()
