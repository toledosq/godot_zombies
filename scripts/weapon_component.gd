class_name WeaponComponent extends InventoryComponent

signal active_weapon_changed(slot_idx: int, weapon: WeaponData)

@export var active_slot: int = 0

func set_active_slot(idx: int) -> void:
	if idx < 0 or idx >= max_slots:
		return
	active_slot = idx
	var w = inventory.slots[idx]
	emit_signal("active_weapon_changed", idx, w)

func _ready() -> void:
	inventory.max_slots = max_slots

func add_item(item: ItemData, quantity: int = 1) -> Dictionary:
	if not item is WeaponData:
		push_warning("WeaponComponent only accepts WeaponData")
		var result = {
			"added": 0,		 # how many items went in
			"rejected": quantity  # leftovers
		}
		return result
	return super.add_item(item, quantity)
