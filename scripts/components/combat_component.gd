class_name CombatComponent extends Node3D

var collision_mask: int = 1

var atk_type: String
var atk_range: float
var atk_range_melee: float
var dmg_type: String
var dmg_ranged: int
var dmg_melee: int

@onready var melee_attack_area: Area3D = $MeleeAttackArea
@onready var melee_attack_shape: CollisionShape3D = $MeleeAttackArea/CollisionShape3D

@export var debug_sphere_scene: PackedScene = preload("res://scenes/tests/DebugSphere.tscn")

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
	var origin: Vector3	 = global_transform.origin
	var forward: Vector3 = -global_transform.basis.z.normalized()
	var to_point: Vector3 = origin + forward * atk_range

	# 2) Build a ray-query, excluding self and parent (the Player)
	var query = PhysicsRayQueryParameters3D.create(origin, to_point, collision_mask, [self, get_parent()])
	query.collide_with_areas  = false
	query.collide_with_bodies = true

	# 3) Cast the ray
	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(query)

	# 4) If we hit something, check for apply_damage() and call it
	if result:
		print("CombatComponent: Attack Ray collided with %s" % result.collider)
		var collider = result.collider
		if collider.has_method("apply_damage"):
			collider.apply_damage(dmg_ranged)
		
		# - debug: spawn a sphere at hit point -
		var debug_sphere = debug_sphere_scene.instantiate()
		get_tree().current_scene.add_child(debug_sphere)
		debug_sphere.global_transform.origin = result.position
