class_name InventoryUI extends Control

signal inventory_opened
signal inventory_closed

@export var columns: int = 4
var inv_comp: InventoryComponent
var inventory: Inventory

@onready var grid: GridContainer = $CenterContainer/HBoxContainer/GridContainer


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
		var panel = Panel.new()
		panel.custom_minimum_size = Vector2(64,64)
		panel.mouse_filter = Control.MOUSE_FILTER_PASS
		panel.tooltip_text = ""
		
		# Icon
		var icon = TextureRect.new()
		icon.name = "Icon"
		icon.expand = true
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		panel.add_child(icon)
		
		# Stack Count
		var lbl = Label.new()
		lbl.name = "Count"
		lbl.anchor_right = 1.0
		lbl.anchor_bottom = 1.0
		lbl.offset_right = -4
		lbl.offset_bottom = -4
		panel.add_child(lbl)
		
		grid.add_child(panel)


func _on_inventory_changed(_item: ItemData, _qty: int) -> void:
	_refresh_all()


func _on_inventory_full(item: ItemData, qty: int) -> void:
	print("Inventory full - dropped %d %s" % [qty, item.display_name])


func _refresh_all() -> void:
	# Loop 0..max_slots-1
	for i in inventory.max_slots:
		var panel = grid.get_child(i)
		if i < inventory.slots.size() and inventory.slots[i].item:
			var slot = inventory.slots[i]
			# Load icon
			panel.get_node("Icon").texture = slot.item.icon
			panel.get_node("Count").text = str(slot.quantity)
			panel.tooltip_text = slot.item.display_name
		else:
			panel.get_node("Icon").texture = null
			panel.get_node("Count").text = ""
			panel.tooltip_text = ""


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
