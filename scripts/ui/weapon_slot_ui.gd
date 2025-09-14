class_name WeaponSlotUI extends InventorySlotUI


func setup(component: InventoryComponent) -> void:
	inv_comp = component
	inventory = inv_comp.inventory
	
	# Connect signals
	inv_comp.connect("item_added", _on_inventory_changed)
	inv_comp.connect("item_removed", _on_inventory_changed)
	inv_comp.connect("inventory_full", Callable(self, "_on_inventory_full"))
	
	# Connect to weapon-specific signals if this is a WeaponComponent
	if component is WeaponComponent:
		var weapon_comp = component as WeaponComponent
		weapon_comp.connect("ammo_changed", _on_ammo_changed)
		weapon_comp.connect("active_weapon_changed", _on_active_weapon_changed)
	
	refresh()

### OVERRIDES IventorySlotUI.refresh() to allow custom behavior
func refresh() -> void:
	# var slot = slot_index < inventory.slots.size() ? inventory.slots[slot_index] : null
	var slot = inventory.slots[slot_index] if slot_index < inventory.slots.size() else null
	var weapon = slot.item as WeaponData
	print("INV Weapon Slot %d refreshing" % slot_index)
	
	if slot and weapon and icon:
		icon.texture = weapon.icon
		count_label.text = ("%d/%d" % [weapon.current_ammo, weapon.mag_size])
		tooltip_text = weapon.display_name
	else:
		if icon:
			icon.texture = null
		else:
			print("No icon???")
		if count_label:
			count_label.text = ""
		tooltip_text = ""

### OVERRIDES IventorySlotUI._can_drop_data() to check item type is WeaponData
func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	# Don't let the data drop if the item isn't a weapon
	if data.has("item") and data["item"] is not WeaponData:
		return false
	return data is Dictionary and data.has("src_index")

func _on_inventory_changed(_index: int, _item: ItemData, _qty: int) -> void:
	print("WeaponSlotUI: Refreshing slot %d" % slot_index)
	refresh()

func _on_ammo_changed(changed_slot_idx: int, current_ammo: int, max_ammo: int) -> void:
	# Only refresh if this is the slot that changed
	if changed_slot_idx == slot_index:
		print("WeaponSlotUI: Ammo changed for slot %d: %d/%d" % [slot_index, current_ammo, max_ammo])
		refresh()

func _on_active_weapon_changed(changed_slot_idx: int, weapon: WeaponData) -> void:
	# Refresh all weapon slots when active weapon changes to update display
	print("WeaponSlotUI: Active weapon changed, refreshing slot %d" % slot_index)
	refresh()

### OVERRIDES InventorySlotUI._handle_shift_click() for weapon-specific behavior
func _handle_shift_click() -> void:
	# Check if this weapon slot has an item
	if slot_index >= inventory.slots.size():
		return
	var slot = inventory.slots[slot_index]
	if not slot.item:
		return
	
	# Always try to unequip weapon to player inventory (regardless of container state)
	_unequip_weapon_to_inventory()

func _unequip_weapon_to_inventory() -> void:
	var inventory_ui = get_tree().get_first_node_in_group("inventory_ui") as InventoryUI
	if not inventory_ui or not inventory_ui.player_inv_component:
		return
	
	var weapon_slot = inventory.slots[slot_index]
	if not weapon_slot.item:
		return
	
	var weapon = weapon_slot.item as WeaponData
	var player_inv = inventory_ui.player_inv_component.inventory
	
	# Check if player inventory has space
	if not player_inv.has_space_for(weapon, 1):
		print("Cannot unequip weapon - player inventory full")
		return
	
	# Add weapon to player inventory
	var result = player_inv.add_item(weapon, 1)
	if result.added > 0:
		# Remove weapon from weapon slot
		weapon_slot.item = null
		weapon_slot.quantity = 0
		
		# Emit signals for UI updates
		inv_comp.emit_signal("item_removed", slot_index, weapon, 1)
		inventory_ui.player_inv_component.emit_signal("item_added", result.index, weapon, 1)
		
		print("Unequipped %s to player inventory" % weapon.display_name)
	else:
		print("Failed to unequip weapon - could not add to player inventory")
