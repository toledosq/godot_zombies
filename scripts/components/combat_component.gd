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
		set_melee_area_size(atk_range_melee)
	else:
		# TODO: unarmed stats should come from player skills
		atk_type = "melee"
		atk_range = 0.0
		atk_range_melee = 1.0
		dmg_type = "physical"
		dmg_ranged = 0
		dmg_melee = 5
		set_melee_area_size(atk_range_melee)


func set_melee_area_size(size:float):
	melee_attack_shape.shape.radius = size
	melee_attack_area.transform.origin = Vector3(0,0,-size)


func attack_melee() -> void:
	print("CombatComponent: Melee Attack")

	var nearest_target = null
	var nearest_distance := INF
	
	# Optional: Add a small delay or animation trigger here before the attack executes.
	
	# Get bodies overlapping with the AttackArea
	for body in melee_attack_area.get_overlapping_bodies():
		# Exclude self and parent
		if body == self or body == get_parent():
			continue
		# Check that body is valid
		if not is_instance_valid(body) or not body.is_inside_tree():
			continue
		# Check that body is not GroundPhysics
		if body.name == "GroundPhysics":
			continue
		
		var dist := global_position.distance_to(body.global_position)
		if dist < nearest_distance:
			nearest_distance = dist
			nearest_target = body
	
	# Apply attack to nearest target within AttackArea
	if nearest_target:
		print("Hit:", nearest_target.name, "for", dmg_melee, dmg_type)
		if nearest_target.has_method("apply_damage"):
			nearest_target.apply_damage(dmg_melee)
		if debug_sphere_scene:
			var sphere = debug_sphere_scene.instantiate()
			get_tree().current_scene.add_child(sphere)
			sphere.global_transform.origin = nearest_target.global_position
	else:
		print("No valid targets in melee range.")


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
