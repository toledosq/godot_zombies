# res://items/ItemData.gd
extends Resource
class_name ItemData

# Item attributes
@export var id: String
@export var icon_file: String
@export var scene_file: String
@export var display_name: String
@export var description: String
@export var category: String
@export var subcategory: String
@export var tags: String
@export var value: int
@export var weight: float
@export var max_stack: int
@export var sort_order: int
@export var spawn_chance: float
@export var equip_slot: String
@export var durability_max: int
@export var durability: int
@export var dmg: int
@export var dmg_type: String
@export var atk_speed: float
@export var atk_range: float
@export var recoil: float
@export var ammo_type: String
@export var mag_size: int
@export var reload_time: float
@export var armor_type: String
@export var resist_phys: float
@export var resist_fire: float
@export var consume_duration: float
@export var effect_type: String
@export var effect_value: int
@export var effect_duration: float
@export var cooldown: float
@export var craftable: String
@export var recipe_id: String
@export var recyclable: String
@export var recyclable_id: String
