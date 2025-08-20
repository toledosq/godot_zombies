class_name Player extends CharacterBody3D

signal player_health_changed(player_id_:int, current: int, maximum: int)
signal player_died(player_id_: int)
signal weapon_equipped(slot_idx: int, weapon: WeaponData)
signal weapon_unequipped(slot_idx: int)
signal active_weapon_changed(slot_idx: int, weapon: WeaponData)

@export var speed := 5.0

var player_id: int
var player_name: String
var previous_transform: Transform3D
var movement_enabled := false
var rotation_enabled := false

@onready var player_controller: PlayerController = $PlayerController
@onready var health_component: HealthComponent = $HealthComponent
@onready var inventory_component: InventoryComponent = $InventoryComponent
@onready var weapon_component: WeaponComponent = $WeaponComponent
@onready var combat_component: CombatComponent = $CombatComponent
@onready var interaction_component: Node3D = $InteractionComponent
@onready var player_hud: PlayerHud = $HUD
@onready var inventory_ui: Control = $InventoryUI
@onready var body = $Body  # Path to visible mesh
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var camera_rig: Node3D = $PlayerCamera


func _ready() -> void:
	# Connect player controller
	player_controller.connect("attack", _on_attack)
	player_controller.connect("interact", interaction_component._try_interact)
	player_controller.connect("toggle_inventory_ui", _on_toggle_inventory_ui)
	player_controller.connect("test_input", _on_test_input_event)
	player_controller.connect("reload", _on_reload_input)
	player_controller.connect("set_active_slot", _on_set_active_slot)
	
	# Mark the inventory component as belonging to player
	inventory_component.add_to_group("player_inventory")
	
	# Connect player Health Component
	print("Player: Connecting Health Component")
	health_component.connect("health_changed", _on_health_changed)
	health_component.connect("died", _on_player_died)
	
	# Initialize HUD
	print("Player: Initializing HUD")
	var gsm = get_node("/root/Main/GameStateManager")
	gsm.mouse_mode_changed.connect(player_hud._on_mouse_mode_changed)
	emit_current_health()
	
	# Connect to Weapon Component
	weapon_component.connect("active_weapon_changed", _on_active_weapon_changed)
	weapon_component.connect("reload_started", _on_reload_started)
	weapon_component.connect("reload_complete", _on_reload_complete)
	weapon_component.connect("request_ammo", _on_request_ammo)
	weapon_component.combat_component = combat_component
	weapon_component.set_active_slot(0)
	
	# Connect to Inventory UI and run initial setup
	inventory_ui.connect("weapon_equipped", _on_weapon_equipped)
	inventory_ui.connect("weapon_unequipped", _on_weapon_unequipped)
	inventory_ui.setup_player_grid(inventory_component)
	inventory_ui.setup_weapon_slots(weapon_component)
	
	# Hook up InteractionComponent -> InventoryUI
	interaction_component.connect("container_inventory_received", _on_container_inventory_received)
	interaction_component.connect("container_inventory_closed", _on_container_inventory_closed)
	
	# Set camera rig target to self
	camera_rig.set_target(self)
	
	# Enable input
	rotation_enabled = true
	movement_enabled = true


func _physics_process(delta) -> void:
	if movement_enabled:
		_handle_movement(delta)
	if rotation_enabled:
		_rotate_towards_mouse()


func set_movement_enabled(val: bool) -> void:
	print("Player: set_movement_enabled = %s" % val)
	movement_enabled = val


func set_rotation_enabled(val: bool) -> void:
	print("Player: set_rotation_enabled = %s" % val)
	rotation_enabled = val


func _handle_movement(delta) -> void:
	# Get movement input vector
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	# Get direction from movement input
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	# If movement input is detected, move in the input direction
	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	# If no input detected, come to a stop
	else:
		velocity.x = move_toward(velocity.x, 0, 20.0 * delta)
		velocity.z = move_toward(velocity.z, 0, 20.0 * delta)
	
	# Do movement
	move_and_slide()


func _rotate_towards_mouse() -> void:
	if not camera_rig.camera:
		return

	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera_rig.camera.project_ray_origin(mouse_pos)
	var ray_dir = camera_rig.camera.project_ray_normal(mouse_pos)

	# Project ray onto a horizontal plane at player's Y position
	var plane = Plane(Vector3.UP, global_transform.origin.y)
	var intersection = plane.intersects_ray(ray_origin, ray_dir)

	if intersection:
		var target_pos = intersection
		var direction = target_pos - global_transform.origin
		direction.y = 0  # Flatten direction to horizontal
		if direction.length() > 0.01:
			look_at(global_transform.origin + direction, Vector3.UP)


func _on_test_input_event(test_type: String) -> void:
	match test_type:
		"test_heal":
			print(">>> Applying 10 damage")
			health_component.heal(5)
		"test_damage":
			print(">>> Healing 5 HP")
			health_component.take_damage(10)
		"test_add_item":
			print("Adding 1 bandage")
			inventory_component.add_item(ItemDatabase.get_item("cons_bandage"), 1)
		"test_remove_item":
			print("Removing 1 bandage")
			inventory_component.remove_item(ItemDatabase.get_item("cons_bandage"), 1)
		_:
			print("invalid test type: %s" % test_type)


func _on_toggle_inventory_ui() -> void:
	# If interacting w/ container and UI is visible, disconnect from container and hide UI
	if inventory_ui.visible and interaction_component.is_interacting:
		interaction_component.cancel_interaction()
		inventory_ui.clear_container_grid()
		inventory_ui.visible = false
	# Otherwise, just toggle visibility
	else:
		inventory_ui.visible = not inventory_ui.visible


func _on_inventory_ui_visibility_changed() -> void:
	# Set movement
	if inventory_ui.visible:
		# Only restrict movement when interacting
		if interaction_component.is_interacting:
			set_movement_enabled(false)
	
	elif not inventory_ui.visible:
		set_movement_enabled(true)


func _on_container_inventory_received(inv_comp: InventoryComponent) -> void:
	inventory_ui.setup_container_grid(inv_comp)
	inventory_ui.visible = true


func _on_container_inventory_closed() -> void:
	inventory_ui.clear_container_grid()
	inventory_ui.visible = false


func _on_health_changed(current:int, maximum:int) -> void:
	# Update HUD
	player_hud._on_health_changed(player_id, current, maximum)
	# Announce health change
	emit_signal("player_health_changed", player_id, current, maximum)
	# Play hit flash
	print("Player: HP:", current, "/", maximum)


func _on_player_died() -> void:
	# Update HUD
	player_hud._on_player_died(player_id)
	# Announce player death
	emit_signal("player_died", player_id)
	# Handle death: play animation, disable input, etc.
	print("Player: Player has died!")


func apply_damage(amount: int) -> void:
	health_component.take_damage(amount)


func apply_heal(amount: int) -> void:
	health_component.heal(amount)


func _on_set_active_slot(idx: int) -> void:
	weapon_component.set_active_slot(idx)

func _on_attack() -> void:
	weapon_component.try_attack()

func _on_active_weapon_changed(slot_idx: int, weapon: WeaponData) -> void:
	# Tell the combat_component to update stats
	combat_component.set_weapon_stats(weapon)
	# Tell the HUD
	player_hud._on_active_weapon_changed(slot_idx, weapon)

func _on_weapon_equipped(slot_idx: int, weapon: WeaponData) -> void:
	print("Player: weapon equipped in slot %d" % slot_idx)
	player_hud._on_weapon_equipped(slot_idx, weapon)

func _on_weapon_unequipped(slot_idx: int) -> void:
	print("Player: weapon unequipped in slot %d" % slot_idx)
	player_hud._on_weapon_unequipped(slot_idx)

func _on_reload_input() -> void:
	print("Player: Reload input received")
	weapon_component.reload_weapon()


func _on_reload_started() -> void:
	print("Player: Reload Started")


func _on_reload_complete() -> void:
	print("Player: Reload Complete")


func _on_request_ammo(type: String, amount: int) -> void:
	print("Player: Forwarding ammo request to inventory component")
	var response: int = inventory_component.give_ammo(type, amount)
	print("Player: Received response from inventory component (%d)" % response)
	weapon_component._on_received_ammo(response)

func emit_current_health() -> void:
	print("Player: Sharing current health")
	_on_health_changed(health_component.current_health, health_component.max_health)


func pickup_item(item: ItemData, quantity: int) -> int:
	var result = inventory_component.add_item(item, quantity)
	if result.rejected > 0:
		print("Dropped %d %s because inventory full!" % [result.rejected, item.name])
		return result.rejected
	return 0
