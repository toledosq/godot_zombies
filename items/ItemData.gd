# res://items/ItemData.gd
extends Resource
class_name ItemData

# Item attributes
@export var id: String
@export var iconpath: Texture2D
@export var scenepath: String
@export var display_name: String
@export var description: String
@export var category: String
@export var subcategory: String
@export var tags: Array[String]
@export var value: int
@export var weight: float
@export var stackable: bool
@export var maxstack: int
@export var sortorder: int
@export var spawnweight: float
@export var equipslot: String
@export var durabilitymax: int
@export var durability: int
@export var damagemin: int
@export var damagemax: int
@export var damagetype: String
@export var attackspeed: float
@export var attackrange: float
@export var ammotype: String
@export var magazinesize: int
@export var reloadtime: float
@export var armorvalue: int
@export var armortype: String
@export var physresist: float
@export var fireresist: float
@export var effecttype: String
@export var effectvalue: int
@export var effectduration: float
@export var cooldown: float
@export var craftable: bool
@export var recipeid: String
@export var recyclable: bool
