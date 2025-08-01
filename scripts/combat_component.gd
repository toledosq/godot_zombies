class_name CombatComponent extends Node3D

var atk_type: String
var atk_range: float
var atk_range_melee: float
var dmg_type: String
var dmg_ranged: int
var dmg_melee: int

@onready var melee_attack_area: Area3D = $MeleeAttackArea
@onready var melee_attack_shape: CollisionShape3D = $MeleeAttackArea/CollisionShape3D


func set_weapon_stats(weapon: WeaponData):
	if weapon:
		atk_type = weapon.weapon_type
		atk_range = weapon.ranged_distance
		atk_range_melee = weapon.melee_distance
		dmg_type = weapon.damage_type
		dmg_ranged = weapon.ranged_damage
		dmg_melee = weapon.melee_damage
		set_melee_area_size()

func set_melee_area_size():
	melee_attack_shape.shape.radius = atk_range_melee
	melee_attack_area.transform.origin = Vector3(0,0,-atk_range_melee)

func attack_melee() -> void:
	print("CombatComponent: Melee Attack")

func attack_ranged() -> void:
	print("CombatComponent: Ranged Attack")
