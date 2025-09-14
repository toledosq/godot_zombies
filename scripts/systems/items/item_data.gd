# res://items/ItemData.gd
extends Resource
class_name ItemData

# Base item attributes
@export var id: StringName
@export var icon: Texture2D
@export var scene_file: StringName
@export var display_name: StringName
@export var description: String
@export var category: String
@export var subcategory: String
@export var value: int
@export var weight: float
@export var durability_max: int
@export var durability: int
@export var repairable: bool
@export var repair_cost: int
@export var max_stack: int
@export var sort_order: int
@export var quest_only: bool
@export var equippable: bool
@export var time_to_use: float
@export var craftable: bool
@export var recipe_id: String
@export var recyclable: bool
@export var recyclable_id: String

# Helper function to check if two items are the same type (by ID)
# This is needed since we now use duplicated instances instead of shared references
func is_same_item_type(other: ItemData) -> bool:
	return other != null and self.id == other.id
