extends Node

# Preload your single library resource
@onready var library: ItemLibrary = preload("res://resources/ItemLibrary.tres")

# Return an ItemData resource from the ItemLibrary
func get_item(id: String) -> ItemData:
	for item in library.items:
		if item.id == id:
			return item
	return null
