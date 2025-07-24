class_name WeaponSlotUI extends InventorySlotUI

signal weapon_equipped(slot_idx: int, weapon: WeaponData)
signal weapon_unequipped(slot_idx: int)

func setup(component: InventoryComponent) -> void:
	inv_comp = component
	inventory = inv_comp.inventory
	
	# Connect signals
	inv_comp.connect("item_added", Callable(self, "_on_inventory_changed"))
	inv_comp.connect("item_removed", Callable(self, "_on_inventory_changed"))
	inv_comp.connect("inventory_full", Callable(self, "_on_inventory_full"))
	
	refresh()

### OVERRIDES IventorySlotUI.refresh() to allow custom behavior
func refresh() -> void:
	# var slot = slot_index < inventory.slots.size() ? inventory.slots[slot_index] : null
	var slot = inventory.slots[slot_index] if slot_index < inventory.slots.size() else null
	var weapon = slot.item as WeaponData
	
	if slot and weapon and icon:
		icon.texture = weapon.icon
		count_label.text = ("%d/%d" % [0, weapon.mag_size]) # TODO: Change this to current ammo
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
