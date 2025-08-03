class_name InventoryUI extends Control

signal weapon_equipped(slot_idx: int, weapon: WeaponData)
signal weapon_unequipped(slot_idx: int)

@export var columns: int = 5
@export var slot_scene: PackedScene = preload("res://scenes/ui/InventorySlotUI.tscn")
@export var weapon_slot_scene: PackedScene = preload("res://scenes/ui/WeaponSlotUI.tscn")

var player_inv_component: InventoryComponent
var player_weapon_component: WeaponComponent
var container_inv_component: InventoryComponent

@onready var player_grid: GridContainer = $CenterContainer/HBoxContainer/PlayerInventoryGrid
@onready var container_grid: GridContainer = $CenterContainer/HBoxContainer/ContainerInventoryGrid
@onready var weapon_slots: VBoxContainer = $CenterContainer/HBoxContainer/WeaponSlots


func _ready() -> void:
	visible = false
	container_grid.visible = false # Hide until a container is opened

func setup_player_grid(component: InventoryComponent) -> void:
	player_inv_component = component
	player_grid.columns = columns
	
	_clear_player_grid()
	_populate_player_grid(player_inv_component.max_slots)
	
	# Listen for changes
	player_inv_component.connect("item_added", _on_player_inventory_changed)
	player_inv_component.connect("item_removed", _on_player_inventory_changed)
	player_inv_component.connect("inventory_full", _on_player_inventory_full)
	
	_refresh_player_grid()

func setup_weapon_slots(wc: WeaponComponent) -> void:
	player_weapon_component = wc
	player_weapon_component.connect("item_added", _on_weapon_equipped)
	player_weapon_component.connect("item_removed", _on_weapon_unequipped)
	_clear_weapon_slots()
	_populate_weapon_slots(player_weapon_component.max_slots)

func _populate_weapon_slots(slot_count: int):
	for i in slot_count:
		var slot_ui = weapon_slot_scene.instantiate() as WeaponSlotUI
		slot_ui.slot_index = i
		weapon_slots.add_child(slot_ui)
		slot_ui.setup(player_weapon_component)

func _on_weapon_equipped(idx: int, item: ItemData, _qty: int) -> void:
	print("InventoryUI: Emitting weapon_equipped(%d, item)" % idx)
	emit_signal("weapon_equipped", idx, item)

func _on_weapon_unequipped(idx: int, _item: ItemData, _qty: int) -> void:
	print("InventoryUI: Emitting weapon_unequipped(%d, item)" % idx)
	emit_signal("weapon_unequipped", idx)

func _clear_weapon_slots() -> void:
	for child in weapon_slots.get_children():
		child.queue_free()

func _clear_player_grid() -> void:
	for child in player_grid.get_children():
		child.queue_free()

func _populate_player_grid(slot_count: int) -> void:
	for i in slot_count:
		var slot_ui = slot_scene.instantiate() as InventorySlotUI
		slot_ui.slot_index = i
		player_grid.add_child(slot_ui)
		slot_ui.setup(player_inv_component)

func _on_player_inventory_changed(_index: int, _item: ItemData, _qty: int) -> void:
	_refresh_player_grid()

func _on_player_inventory_full(item: ItemData, qty: int) -> void:
	print("Inventory full - dropped %d %s" % [qty, item.display_name])

func _refresh_player_grid() -> void:
	for i in player_inv_component.max_slots:
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
	container_inv_component.connect("item_added", _on_container_inventory_changed)
	container_inv_component.connect("item_removed", _on_container_inventory_changed)
	
	# Make visible and refresh
	container_grid.visible = true
	_refresh_container_grid()

# Called by Player when InteractionComponent signal "inventory gone"
func clear_container_grid() -> void:
	if container_inv_component:
		container_inv_component.disconnect("item_added", _on_container_inventory_changed)
		container_inv_component.disconnect("item_removed", _on_container_inventory_changed)
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

func _on_container_inventory_changed(_index: int, _item: ItemData, _qty: int) -> void:
	_refresh_container_grid()

func _refresh_container_grid() -> void:
	for i in container_inv_component.inventory.max_slots:
		var slot_ui = container_grid.get_child(i) as InventorySlotUI
		slot_ui.refresh()
