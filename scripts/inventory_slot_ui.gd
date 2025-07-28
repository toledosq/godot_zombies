class_name InventorySlotUI extends Panel

@export var slot_index: int = 0

var inv_comp: InventoryComponent
var inventory: Inventory
var square_size = Vector2(64, 64)

@onready var icon: TextureRect = $Icon
@onready var count_label:Label = $Count


func _ready() -> void:
	# Force icon to be exactly 64×64
	icon.custom_minimum_size = square_size

	# Use aspect-preserving scaling (it’ll downscale large textures, but never stretch them)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func setup(component: InventoryComponent) -> void:
	inv_comp = component
	inventory = inv_comp.inventory
	
	# Listen for changes
	inv_comp.connect("item_added", _on_inventory_changed)
	inv_comp.connect("item_removed", _on_inventory_changed)
	
	refresh()


func refresh() -> void:
	# var slot = slot_index < inventory.slots.size() ? inventory.slots[slot_index] : null
	var slot = inventory.slots[slot_index] if slot_index < inventory.slots.size() else null
	
	if slot and slot.item and icon:
		icon.texture = slot.item.icon
		count_label.text = str(slot.quantity)
		tooltip_text = slot.item.display_name
	else:
		if icon:
			icon.texture = null
		else:
			print("No icon???")
		if count_label:
			count_label.text = ""
		tooltip_text = ""

func _on_inventory_changed(_index: int, _item: ItemData, _qty: int) -> void:
	refresh()

# Drag & Drop hooks
func _get_drag_data(_position: Vector2) -> Variant:
	if slot_index >= inventory.slots.size(): return null
	var slot = inventory.slots[slot_index]
	if not slot.item: return null
	
	# Package the source item type, index, and component
	var data = { 
		"item": slot.item,
		"src_index": slot_index, 
		"src_comp": inv_comp
	}
	
	print(data)
	
	# Make drag preview
	var preview = TextureRect.new()
	preview.texture = icon.texture
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.custom_minimum_size = square_size
	set_drag_preview(preview)
	return data

func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("src_index")

func _drop_data(_position: Vector2, data: Variant) -> void:
	var src_idx = data["src_index"]
	var src_comp = data["src_comp"]
	var dst_idx = slot_index
	var dst_comp = inv_comp
	
	# 1) Same inventory -> swap slots
	if src_comp == dst_comp:
		# Simple swap within inventory
		src_comp.inventory.swap_slots(src_idx, dst_idx)
		src_comp.emit_signal("item_removed", src_idx, null, 0)
		dst_comp.emit_signal("item_added", dst_idx, dst_comp.inventory.slots[dst_idx].item, 0)
		return
	
	# 2) Cross-inventory -> direct placement
	var src_slot = src_comp.inventory.slots[src_idx]
	if not src_slot.item:
		return
	
	# 2a) empty target slot -> move up to one full stack
	var dst_slot = dst_comp.inventory.slots[dst_idx]
	var moved = 0
	if dst_slot.item == null:
		moved = min(src_slot.quantity, src_slot.item.max_stack)
		dst_slot.item = src_slot.item
		dst_slot.quantity = moved
	
	# 2b) same item in target slot -> top off existing stack
	elif dst_slot.item == src_slot.item:
		var space = dst_slot.item.max_stack - dst_slot.quantity
		moved = min(space, src_slot.quantity)
		dst_slot.quantity += moved
	
	# 2c) different item in target -> swap entire stacks
	else:
		var tmp_item = dst_slot.item
		var tmp_qty = dst_slot.quantity
		dst_slot.item = src_slot.item
		dst_slot.quantity = src_slot.quantity
		src_slot.item = tmp_item
		src_slot.quantity = tmp_qty
		moved = dst_slot.quantity
		
		# Emit and exit early
		src_comp.emit_signal("item_removed", src_idx, tmp_item, tmp_qty)
		dst_comp.emit_signal("item_added", dst_idx, dst_slot.item, moved)
		return
	
	# 3) Remove moved quantity from source
	src_slot.quantity -= moved
	if src_slot.quantity <= 0:
		src_slot.item = null
		src_slot.quantity = 0

	# 4) fire signals so both UIs refresh slots
	src_comp.emit_signal("item_removed", src_idx, dst_slot.item, moved)
	dst_comp.emit_signal("item_added", dst_idx, dst_slot.item, moved)
