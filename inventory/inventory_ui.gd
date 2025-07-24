class_name InventoryUI extends Control

signal inventory_opened
signal inventory_closed

@export var columns: int = 4
@export var slot_scene: PackedScene = preload("res://ui/InventorySlotUI.tscn")

var player_inv_component: InventoryComponent
var player_inventory: Inventory

var container_inv_component: InventoryComponent

@onready var player_grid: GridContainer = $CenterContainer/HBoxContainer/PlayerInventoryGrid
@onready var container_grid: GridContainer = $CenterContainer/HBoxContainer/ContainerInventoryGrid


func _ready() -> void:
	visible = false
	container_grid.visible = false # Hide until a container is opened


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
	
	_clear_player_grid()
	_populate_player_grid(player_inventory.max_slots)
	
	# Listen for changes
	player_inv_component.connect("item_added", Callable(self, "_on_player_inventory_changed"))
	player_inv_component.connect("item_removed", Callable(self, "_on_player_inventory_changed"))
	player_inv_component.connect("inventory_full", Callable(self, "_on_player_inventory_full"))
	
	_refresh_player_grid()


func _clear_player_grid() -> void:
	for child in player_grid.get_children():
		child.queue_free()


func _populate_player_grid(slot_count: int) -> void:
	for i in slot_count:
		var slot_ui = slot_scene.instantiate() as InventorySlotUI
		slot_ui.slot_index = i
		player_grid.add_child(slot_ui)
		slot_ui.setup(player_inv_component)


func _on_player_inventory_changed(_item: ItemData, _qty: int) -> void:
	_refresh_player_grid()


func _on_player_inventory_full(item: ItemData, qty: int) -> void:
	print("Inventory full - dropped %d %s" % [qty, item.display_name])


func _refresh_player_grid() -> void:
	for i in player_inventory.max_slots:
		var slot_ui = player_grid.get_child(i) as InventorySlotUI
		slot_ui.refresh()


# Called by Player when InteractionComponent signals "got inventory"
func setup_container_grid(inv_comp: InventoryComponent) -> void:
	if container_inv_component == inv_comp:
		return # already have the component stored
	
	container_inv_component = inv_comp
	container_grid.columns = columns
	_clear_container_grid()
	_populate_container_grid(container_inv_component.inventory.max_slots)
	
	# Listen for changes
	container_inv_component.connect("item_added", Callable(self, "_on_container_inventory_changed"))
	container_inv_component.connect("item_removed", Callable(self, "_on_container_inventory_changed"))
	container_inv_component.connect("inventory_full", Callable(self, "_on_inventory_full"))
	
	# Make visible and refresh
	container_grid.visible = true
	_refresh_container_grid()


# Called by Player when InteractionComponent signal "inventory gone"
func clear_container_grid() -> void:
	if container_inv_component:
		container_inv_component.disconnect("item_added", Callable(self, "_on_container_inventory_changed"))
		container_inv_component.disconnect("item_removed", Callable(self, "_on_container_inventory_changed"))
		container_inv_component.disconnect("inventory_full", Callable(self, "_on_inventory_full"))
		container_inv_component = null
	_clear_container_grid()
	container_grid.visible = false


func _clear_container_grid() -> void:
	for child in container_grid.get_children():
		child.queue_free()

func _populate_container_grid(slot_count: int) -> void:
	for i in slot_count:
		var slot_ui = slot_scene.instantiate() as InventorySlotUI
		slot_ui.slot_index = i
		container_grid.add_child(slot_ui)
		slot_ui.setup(container_inv_component)

func _on_container_inventory_changed(_item: ItemData, _qty: int) -> void:
	_refresh_container_grid()

func _refresh_container_grid() -> void:
	for i in container_inv_component.inventory.max_slots:
		var slot_ui = container_grid.get_child(i) as InventorySlotUI
		slot_ui.refresh()
