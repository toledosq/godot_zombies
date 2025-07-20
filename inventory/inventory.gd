class_name Inventory extends Resource

@export var max_slots: int = 30
@export var slots: Array[InventorySlot] = []


func has_space_for(item: ItemData, quantity: int = 1) -> bool:
	var remaining = quantity
	
	# First, check space in existing stacks
	for slot in slots:
		if slot.item == item and slot.quantity > item.max_stack:
			var space_in_stack = item.max_stack - slot.quantity
			remaining -= min(space_in_stack, remaining)
			if remaining <= 0:
				return true # It all fits
	
	# Next, check if there's space for new stacks
	var free_slots = max_slots - slots.size()
	var new_stacks_needed = ceil(float(remaining) / item.max_stack)
	
	# Return true/false depending on space
	return new_stacks_needed <= free_slots


func add_item(item: ItemData, quantity: int = 1) -> Dictionary:
	var remaining = quantity
	var added = 0
	
	# Fill existing stacks
	for slot in slots:
		if slot.item == item and slot.quantity < item.max_stack:
			var space_in_stack = item.max_stack - slot.quantity
			var to_add = min(space_in_stack, remaining)
			slot.quantity += to_add
			added += to_add
			remaining -= to_add
			if remaining == 0:
				break
	
	# Add new stacks for leftovers
	while remaining > 0 and slots.size() < max_slots:
		var to_add = min(item.max_stack, remaining)
		var new_slot = InventorySlot.new()
		new_slot.item = item
		new_slot.quantity = to_add
		slots.append(new_slot)
		added += to_add
		remaining -= to_add
	
	# Return a dictionary with details
	return {
		"added": added,			# total items successfully added
		"rejected": remaining	# total items that overflowed
	}


func remove_item(item: ItemData, quantity: int = 1) -> bool:
	var remaining = quantity
	
	for slot in slots:
		if slot.item == item:
			if slot.quantity >= remaining:
				slot.quantity -= remaining
				if slot.quantity == 0:
					slots.erase(slot)
				return true
			else:
				remaining -= slot.quantity
				slots.erase(slot)
	
	# If we still have remaining quantity, we couldn't remove enough
	return remaining == 0


func get_quantity(item: ItemData) -> int:
	var total = 0
	for slot in slots:
		if slot.item == item:
			total += slot.quantity
	return total
