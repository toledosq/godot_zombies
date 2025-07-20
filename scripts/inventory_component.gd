class_name InventoryComponent extends Node

@export var inventory: Inventory = Inventory.new()

# expose max_slots via the component
@export var max_slots: int:
	set(value):
		inventory.max_slots = value
		max_slots = value
	get:
		return max_slots


func _ready() -> void:
	print("InventoryComponent: Max Slots = %d" % max_slots)


func add_item(item: ItemData, quantity: int = 1) -> Dictionary:
	return inventory.add_item(item, quantity)


func remove_item(item: ItemData, quantity: int = 1) -> int:
	return inventory.remove_item(item, quantity)


func has_space_for(item: ItemData, quantity: int = 1) -> bool:
	return inventory.has_space_for(item, quantity)


func get_quantity(item: ItemData) -> int:
	return inventory.get_quantity(item)


func save(path: String) -> void:
	print("InventoryComponent: Saving inventory to %s" % path)
	ResourceSaver.save(inventory, path)


func load(path: String) -> void:
	var loaded_inventory = ResourceLoader.load(path)
	if loaded_inventory:
		inventory = loaded_inventory
		print("InventoryComponent: Loaded saved inventory")
	else:
		print("InventoryComponent: Could not find saved inventory")
