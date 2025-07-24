class_name LootContainer extends StaticBody3D

signal toggle_inventory(external_inventory_owner)

@onready var inventory_component: InventoryComponent = $InventoryComponent

func _ready() -> void:
	inventory_component.max_slots = 5
	inventory_component.add_item(ItemDatabase.get_item("wep_mp5"), 2)

func interact() -> void:
	print(self, " : interacted with")
	toggle_inventory.emit(self)
