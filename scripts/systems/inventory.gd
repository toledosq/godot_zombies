class_name Inventory
extends Resource

@export var max_slots: int = 10:
	set(value):
		max_slots = value
		_ensure_slots_length()
	get:
		return max_slots

@export var slots: Array[InventorySlot] = []

func _init():
	_ensure_slots_length()

func has_space_for(item: ItemData, quantity: int = 1) -> bool:
	var remaining = quantity

	# 1) Fill existing partial stacks
	for slot in slots:
		if slot.item == item and slot.quantity < item.max_stack:
			var space = item.max_stack - slot.quantity
			remaining -= min(space, remaining)
			if remaining <= 0:
				return true	 # it all fits into existing stacks

	# 2) Count how many empty slots remain
	var empty_slots = 0
	for slot in slots:
		if slot.item == null:
			empty_slots += 1

	# How many new stacks we'd need?
	var stacks_needed = ceil(remaining / float(item.max_stack))

	return stacks_needed <= empty_slots

func add_item(item: ItemData, quantity: int = 1) -> Dictionary:
	var remaining := quantity
	var added := 0
	var changed_index := 0

	# 1) Top up existing stacks
	for slot in slots:
		if slot.item == item and slot.quantity < item.max_stack:
			var space = item.max_stack - slot.quantity
			var to_add = min(space, remaining)
			slot.quantity += to_add
			added += to_add
			remaining -= to_add
			if remaining == 0:
				break

	# 2) Create new stacks in empty slots
	for slot in slots:
		if remaining == 0:
			break
		if slot.item == null:
			var to_add = min(item.max_stack, remaining)
			slot.item = item
			slot.quantity = to_add
			added += to_add
			remaining -= to_add
		changed_index += 1

	return {
		"added": added,		 # how many items went in
		"rejected": remaining,
		"index": changed_index  # leftovers
	}

func remove_item(item: ItemData, quantity: int = 1) -> Dictionary:
	var remaining = quantity
	var changed_index := 0
	var total_removal := false
	
	for i in range(slots.size(), 0, -1):
		# Track which slot is being tried
		changed_index = i-1
		var slot = slots[changed_index]
		if slot.item == item:
			if slot.quantity > remaining:
				slot.quantity -= remaining
				remaining = 0
				total_removal = true
			else:
				remaining -= slot.quantity
				# clear that slot instead of removing it
				slot.item = null
				slot.quantity = 0
				if remaining == 0:
					total_removal = true
	
	return {
		"total_removal": total_removal,
		"amount_removed": quantity - remaining,
		"index": changed_index
	}

func swap_slots(a: int, b: int) -> void:
	# no need to re-ensure length here
	if a >= 0 and b >= 0 and a < max_slots and b < max_slots:
		var tmp = slots[a]
		slots[a] = slots[b]
		slots[b] = tmp

func _ensure_slots_length() -> void:
	# Expand with empty InventorySlot until we hit max_slots
	while slots.size() < max_slots:
		slots.append(InventorySlot.new())
	# Trim extras if max_slots got smaller
	while slots.size() > max_slots:
		slots.pop_back()

func print_slot_members() -> Array:
	var pa_: Array = []
	for slot in slots:
		if slot.item:
			pa_.append(slot.item.id)
		else:
			pa_.append(null)
	return pa_
