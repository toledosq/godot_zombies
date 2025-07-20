class_name InventoryComponent extends Node

@export var inventory: Inventory = Inventory.new()

# expose max_slots via the component
@export var max_slots: int:
	set(value):
		inventory.max_slots = value
	get:
		return max_slots

func add_item(item: ItemData, quantity: int = 1) -> Dictionary:
	return inventory.add_item(item, quantity)

func remove_item(item: ItemData, quantity: int = 1) -> bool:
	return inventory.remove_item(item, quantity)

func has_space_for(item: ItemData, quantity: int = 1) -> bool:
	return inventory.has_space_for(item, quantity)

func get_quantity(item: ItemData) -> int:
	return inventory.get_quantity(item)
