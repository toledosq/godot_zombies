extends Node

# Preload your single library resource
@onready var library: ItemLibrary = preload("res://resources/item_library.tres")

# Return a duplicated ItemData resource from the ItemLibrary
# This ensures each item instance is unique and modifications don't affect other instances
func get_item(id: String) -> ItemData:
	for item in library.items:
		if item.id == id:
			return item.duplicate(true)  # Deep duplicate to ensure complete isolation
	return null
