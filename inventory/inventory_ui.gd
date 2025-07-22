class_name InventoryUI extends Control

signal inventory_opened
signal inventory_closed

@export var columns: int = 4
@export var slot_scene: PackedScene = preload("res://ui/InventorySlotUI.tscn")
var inv_comp: InventoryComponent
var inventory: Inventory

@onready var grid: GridContainer = $CenterContainer/HBoxContainer/GridContainer


func _ready() -> void:
	visible = false


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


func setup(component: InventoryComponent) -> void:
	inv_comp = component
	inventory = inv_comp.inventory
	grid.columns = columns
	
	_clear_grid()
	_populate_grid(inventory.max_slots)
	
	# Listen for changes
	inv_comp.connect("item_added", Callable(self, "_on_inventory_changed"))
	inv_comp.connect("item_removed", Callable(self, "_on_inventory_changed"))
	inv_comp.connect("inventory_full", Callable(self, "_on_inventory_full"))
	
	_refresh_all()


func _clear_grid() -> void:
	for child in grid.get_children():
		child.queue_free()


func _populate_grid(slot_count: int) -> void:
	for i in slot_count:
		var slot_ui = slot_scene.instantiate() as InventorySlotUI
		slot_ui.slot_index = i
		grid.add_child(slot_ui)
		slot_ui.setup(inv_comp, inventory)


func _on_inventory_changed(_item: ItemData, _qty: int) -> void:
	_refresh_all()


func _on_inventory_full(item: ItemData, qty: int) -> void:
	print("Inventory full - dropped %d %s" % [qty, item.display_name])


func _refresh_all() -> void:
	for i in inventory.max_slots:
		var slot_ui = grid.get_child(i) as InventorySlotUI
		slot_ui.refresh()
