# res://items/ItemData.gd
extends Resource
class_name ItemData

# Base item attributes
@export var id: String
@export var icon_file: String
@export var scene_file: String
@export var display_name: String
@export var description: String
@export var category: String
@export var subcategory: String
@export var value: int
@export var weight: float
@export var durability_max: int
@export var durability: int
@export var max_stack: int
@export var sort_order: int
@export var quest_only: bool
@export var equippable: bool
@export var equip_slot: String
@export var craftable: bool
@export var recipe_id: String
@export var recyclable: bool
@export var recyclable_id: String
