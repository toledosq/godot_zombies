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

# Handle mouse input for shift-click auto-transfer
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if Input.is_key_pressed(KEY_SHIFT):
				_handle_shift_click()

func _handle_shift_click() -> void:
	var inventory_ui = get_tree().get_first_node_in_group("inventory_ui") as InventoryUI
	if not inventory_ui:
		return
	
	# Check if this slot has an item
	if slot_index >= inventory.slots.size():
		return
	var slot = inventory.slots[slot_index]
	if not slot.item:
		return
	
	# Case 1: Container is open -> transfer between inventories
	if inventory_ui.container_inv_component:
		# Determine target inventory component based on current slot's inventory
		var target_inv_comp: InventoryComponent
		if inv_comp == inventory_ui.player_inv_component:
			# Player slot clicked -> transfer to container
			target_inv_comp = inventory_ui.container_inv_component
		elif inv_comp == inventory_ui.container_inv_component:
			# Container slot clicked -> transfer to player
			target_inv_comp = inventory_ui.player_inv_component
		else:
			# Unknown inventory type
			return
		
		# Perform the auto-transfer using the existing transfer logic
		_auto_transfer_to_inventory(target_inv_comp)
	
	# Case 2: No container open, weapon clicked -> auto-equip weapon
	elif slot.item is WeaponData and inv_comp == inventory_ui.player_inv_component:
		_auto_equip_weapon(slot.item as WeaponData)

func _auto_transfer_to_inventory(target_inv_comp: InventoryComponent) -> void:
	# Find the best destination slot using inventory's built-in logic
	var src_slot = inventory.slots[slot_index]
	if not src_slot.item:
		return
	
	# Use the target inventory's add_item method to find optimal placement
	var target_inventory = target_inv_comp.inventory
	if not target_inventory.has_space_for(src_slot.item, src_slot.quantity):
		print("Cannot transfer - target inventory full")
		return
	
	# Try to add the item to the target inventory
	var result = target_inventory.add_item(src_slot.item, src_slot.quantity)
	var transferred = result.added
	
	if transferred > 0:
		# Remove the transferred amount from source
		src_slot.quantity -= transferred
		if src_slot.quantity <= 0:
			src_slot.item = null
			src_slot.quantity = 0
		
		# Emit signals so both UIs refresh
		inv_comp.emit_signal("item_removed", slot_index, src_slot.item, transferred)
		target_inv_comp.emit_signal("item_added", result.index, src_slot.item, transferred)
		
		print("Auto-transferred %d %s" % [transferred, src_slot.item.display_name if src_slot.item else "items"])

func _auto_equip_weapon(weapon: WeaponData) -> void:
	var inventory_ui = get_tree().get_first_node_in_group("inventory_ui") as InventoryUI
	if not inventory_ui or not inventory_ui.player_weapon_component:
		return
	
	var weapon_comp = inventory_ui.player_weapon_component
	var weapon_inventory = weapon_comp.inventory
	
	# Find the best slot to equip the weapon
	var target_slot_idx = _find_best_weapon_slot(weapon_comp)
	if target_slot_idx == -1:
		print("Cannot auto-equip weapon - no available slots")
		return
	
	var target_slot = weapon_inventory.slots[target_slot_idx]
	var src_slot = inventory.slots[slot_index]
	
	# If target slot has a weapon, swap it back to player inventory
	if target_slot.item:
		var displaced_weapon = target_slot.item
		# Try to add the displaced weapon back to player inventory
		var result = inv_comp.inventory.add_item(displaced_weapon, 1)
		if result.added == 0:
			print("Cannot auto-equip - inventory full, cannot swap weapons")
			return
		
		# Remove the displaced weapon from weapon slot
		target_slot.item = null
		target_slot.quantity = 0
		weapon_comp.emit_signal("item_removed", target_slot_idx, displaced_weapon, 1)
	
	# Move weapon from inventory to weapon slot
	target_slot.item = weapon
	target_slot.quantity = 1
	
	# Remove from player inventory
	src_slot.item = null
	src_slot.quantity = 0
	
	# Emit signals for UI updates
	weapon_comp.emit_signal("item_added", target_slot_idx, weapon, 1)
	inv_comp.emit_signal("item_removed", slot_index, weapon, 1)
	
	print("Auto-equipped %s to weapon slot %d" % [weapon.display_name, target_slot_idx])

func _find_best_weapon_slot(weapon_comp: WeaponComponent) -> int:
	var weapon_inventory = weapon_comp.inventory
	
	# First, try to find an empty slot
	for i in weapon_inventory.max_slots:
		var slot = weapon_inventory.slots[i]
		if not slot.item:
			return i
	
	# If no empty slots, use the active slot for replacement
	return weapon_comp.active_slot

# Drag & Drop hooks
func _get_drag_data(_position: Vector2) -> Variant:
	if slot_index >= inventory.slots.size(): return null
	var slot = inventory.slots[slot_index]
	if not slot.item: return null
	
	# Package the source item type, index, and component
	var data = { 
		"item": slot.item,
		"qty": slot.quantity,
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
		# Store the items before swapping to emit correct signals
		# This is crucial for proper HUD updates during weapon swaps
		var src_slot = src_comp.inventory.slots[src_idx]
		var dst_slot = dst_comp.inventory.slots[dst_idx]
		var src_item = src_slot.item
		var dst_item = dst_slot.item
		var src_qty = src_slot.quantity
		var dst_qty = dst_slot.quantity
		
		# Perform the actual swap in the inventory
		src_comp.inventory.swap_slots(src_idx, dst_idx)
		
		# Emit proper signals for both slots after the swap
		# This ensures both the inventory UI and player HUD update correctly
		
		# Update the source slot (now contains what was in destination)
		if dst_item:
			src_comp.emit_signal("item_added", src_idx, dst_item, dst_qty)
		else:
			src_comp.emit_signal("item_removed", src_idx, src_item, src_qty)
		
		# Update the destination slot (now contains what was in source)
		if src_item:
			dst_comp.emit_signal("item_added", dst_idx, src_item, src_qty)
		else:
			dst_comp.emit_signal("item_removed", dst_idx, dst_item, dst_qty)
		
		print("Swapped weapons: slot %d (%s) <-> slot %d (%s)" % [
			src_idx, src_item.display_name if src_item else "empty",
			dst_idx, dst_item.display_name if dst_item else "empty"
		])
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
