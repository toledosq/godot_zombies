class_name InventoryComponent extends Node

signal item_added(item: ItemData, quantity: int)
signal item_removed(item: ItemData, quantity: int)
signal inventory_full(item: ItemData, quantity: int)

@export var inventory: Inventory = Inventory.new()
@export var max_slots: int:
	set(value):
		inventory.max_slots = value
		max_slots = value
	get:
		return max_slots


func _ready() -> void:
	print("InventoryComponent: Max Slots = %d" % max_slots)


func add_item(item: ItemData, quantity: int = 1) -> Dictionary:
	var result = inventory.add_item(item, quantity)
	
	if result.added > 0:
		emit_signal("item_added", item, result.added)
	
	if result.rejected > 0:
		emit_signal("inventory_full", item, result.rejected)
	
	return result


func remove_item(item: ItemData, quantity: int = 1) -> int:
	var success = inventory.remove_item(item, quantity)
	if success:
		emit_signal("item_removed", item, quantity)
	return success


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
