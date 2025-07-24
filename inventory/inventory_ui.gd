class_name InventoryUI extends Control

signal inventory_opened
signal inventory_closed

@export var columns: int = 4
@export var slot_scene: PackedScene = preload("res://ui/InventorySlotUI.tscn")
var player_inv_component: InventoryComponent
var player_inventory: Inventory

@onready var player_grid: GridContainer = $CenterContainer/HBoxContainer/PlayerInventoryGrid
@onready var container_grid: GridContainer = $CenterContainer/HBoxContainer/ContainerInventoryGrid


func _ready() -> void:
	# Hide!
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


func setup_player_grid(component: InventoryComponent) -> void:
	player_inv_component = component
	player_inventory = player_inv_component.inventory
	player_grid.columns = columns
	
	_clear_grid()
	_populate_grid(player_inventory.max_slots)
	
	# Listen for changes
	player_inv_component.connect("item_added", Callable(self, "_on_inventory_changed"))
	player_inv_component.connect("item_removed", Callable(self, "_on_inventory_changed"))
	player_inv_component.connect("inventory_full", Callable(self, "_on_inventory_full"))
	
	_refresh_all()


func _clear_grid() -> void:
	for child in player_grid.get_children():
		child.queue_free()


func _populate_grid(slot_count: int) -> void:
	for i in slot_count:
		var slot_ui = slot_scene.instantiate() as InventorySlotUI
		slot_ui.slot_index = i
		player_grid.add_child(slot_ui)
		slot_ui.setup(player_inv_component)


func _on_inventory_changed(_item: ItemData, _qty: int) -> void:
	_refresh_all()


func _on_inventory_full(item: ItemData, qty: int) -> void:
	print("Inventory full - dropped %d %s" % [qty, item.display_name])


func _refresh_all() -> void:
	for i in player_inventory.max_slots:
		var slot_ui = player_grid.get_child(i) as InventorySlotUI
		slot_ui.refresh()
