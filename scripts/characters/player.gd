class_name Player extends CharacterBody3D

signal player_health_changed(player_id_:int, current: int, maximum: int)
signal player_died(player_id_: int)
signal weapon_equipped(slot_idx: int, weapon: WeaponData)
signal weapon_unequipped(slot_idx: int)
signal active_weapon_changed(slot_idx: int, weapon: WeaponData)
signal action_delay_started(seconds: float, cancellable: bool)
signal action_delay_completed
signal action_delay_cancelled

@export var speed := 5.0
@export var sprint_speed_modifier := 1.8
@export var crouch_speed_modifier := 0.6

var player_id: int
var player_name: String
var previous_transform: Transform3D
var movement_enabled := false
var rotation_enabled := false

# Crouching state
var is_crouching := false
var crouch_toggle_active := false
var crouch_hold_active := false

# Sprint state
var is_sprinting := false

# Action delay state
var is_action_delayed := false
var action_delay_cancellable := false
var action_delay_timer: Timer

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
@onready var animation_player: AnimationPlayer = $AnimationPlayer  # Future animation implementation


func _ready() -> void:
	# Setup action delay timer
	action_delay_timer = Timer.new()
	action_delay_timer.wait_time = 1.0
	action_delay_timer.one_shot = true
	action_delay_timer.connect("timeout", _on_action_delay_timeout)
	add_child(action_delay_timer)
	
	# Connect player controller
	player_controller.connect("attack", _on_attack)
	player_controller.connect("interact", _on_interact_with_delay)
	player_controller.connect("toggle_inventory_ui", _on_toggle_inventory_ui)
	player_controller.connect("test_input", _on_test_input_event)
	player_controller.connect("set_active_slot", _on_set_active_slot)
	player_controller.connect("cancel_action", _on_cancel_action_delay)
	
	# Connect crouching inputs
	player_controller.connect("crouch_hold_changed", _on_crouch_hold_changed)
	player_controller.connect("crouch_toggle_pressed", _on_crouch_toggle_pressed)
	
	# Connect sprint input
	player_controller.connect("sprint_changed", _on_sprint_changed)
	
	# Mark the inventory component as belonging to player
	inventory_component.add_to_group("player_inventory")
	
	# Connect player Health Component
	print("Player: Connecting Health Component")
	health_component.connect("health_changed", _on_health_changed)
	health_component.connect("died", _on_player_died)
	
	# Initialize HUD
	print("Player: Initializing HUD")
	emit_current_health()
	
	# Connect action delay signals to HUD
	connect("action_delay_started", player_hud._on_action_delay_started)
	connect("action_delay_completed", player_hud._on_action_delay_completed)
	connect("action_delay_cancelled", player_hud._on_action_delay_cancelled)
	
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
		_handle_crouching()
	if rotation_enabled:
		_rotate_towards_mouse()


func set_movement_enabled(val: bool) -> void:
	print("Player: set_movement_enabled = %s" % val)
	movement_enabled = val


func set_rotation_enabled(val: bool) -> void:
	print("Player: set_rotation_enabled = %s" % val)
	rotation_enabled = val


func _handle_movement(delta) -> void:
	if not movement_enabled:
		return
	# Get movement input vector
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	# Get direction from movement input
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	# Check if sprinting or crouching
	var current_speed = speed
	if is_sprinting and not is_crouching:
		current_speed = speed * sprint_speed_modifier
	elif is_crouching:
		current_speed = speed * crouch_speed_modifier
	
	# If movement input is detected, move in the input direction
	if direction != Vector3.ZERO:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	# If no input detected, come to a stop
	else:
		velocity.x = move_toward(velocity.x, 0, 20.0 * delta)
		velocity.z = move_toward(velocity.z, 0, 20.0 * delta)
	
	# Do movement
	move_and_slide()


func _handle_crouching() -> void:
	# Determine if crouching (either hold or toggle)
	var should_crouch = crouch_hold_active or crouch_toggle_active
	
	# Update crouching state
	if should_crouch != is_crouching:
		is_crouching = should_crouch
		_on_crouch_state_changed(is_crouching)


func _on_crouch_state_changed(crouching: bool) -> void:
	print("Player: Crouch state changed to: ", crouching)
	
	# Future animation implementation hooks
	if animation_player:
		if crouching:
			# Play crouch animation
			if animation_player.has_animation("crouch"):
				animation_player.play("crouch")
			# Future: Adjust collision shape height
			# Future: Adjust camera height
		else:
			# Play stand up animation
			if animation_player.has_animation("stand"):
				animation_player.play("stand")
			# Future: Restore collision shape height
			# Future: Restore camera height


func _on_crouch_hold_changed(is_held: bool) -> void:
	crouch_hold_active = is_held


func _on_crouch_toggle_pressed() -> void:
	crouch_toggle_active = !crouch_toggle_active


func _on_sprint_changed(sprinting: bool) -> void:
	is_sprinting = sprinting


func _rotate_towards_mouse() -> void:
	if not camera_rig.camera:
		return
	
	if not rotation_enabled:
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
		"test_action_delay_short":
			print(">>> Testing short action delay (2s, cancellable)")
			action_delay(2.0, true)
		"test_action_delay_long":
			print(">>> Testing long action delay (5s, non-cancellable)")
			action_delay(5.0, false)
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

func _on_interact_with_delay() -> void:
	print("Player: Interact input received - starting interaction delay")
	# Start action delay for interaction (1.5 seconds, cancellable)
	action_delay(1.5, true)
	# Connect to delay completion to actually do the interaction
	if not action_delay_completed.is_connected(_perform_interact):
		action_delay_completed.connect(_perform_interact, CONNECT_ONE_SHOT)
	if not action_delay_cancelled.is_connected(_cancel_interact):
		action_delay_cancelled.connect(_cancel_interact, CONNECT_ONE_SHOT)

func _perform_interact() -> void:
	print("Player: Performing interaction after delay")
	interaction_component._try_interact()

func _cancel_interact() -> void:
	print("Player: Interaction was cancelled")
	# Disconnect signals if they're still connected
	if action_delay_completed.is_connected(_perform_interact):
		action_delay_completed.disconnect(_perform_interact)
	if action_delay_cancelled.is_connected(_cancel_interact):
		action_delay_cancelled.disconnect(_cancel_interact)


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


# Action delay system
func action_delay(seconds: float, cancellable: bool = true) -> void:
	if is_action_delayed:
		print("Player: Action delay already in progress, cancelling previous delay")
		_cancel_action_delay()
	
	print("Player: Starting action delay for %s seconds (cancellable: %s)" % [seconds, cancellable])
	is_action_delayed = true
	action_delay_cancellable = cancellable
	action_delay_timer.wait_time = seconds
	action_delay_timer.start()
	
	# Disable input during delay
	movement_enabled = false
	rotation_enabled = false
	player_controller.set_action_delay_active(true)
	
	# Notify HUD and other systems
	emit_signal("action_delay_started", seconds, cancellable)


func _on_cancel_action_delay() -> void:
	if not is_action_delayed:
		return
		
	if not action_delay_cancellable:
		print("Player: Cannot cancel non-cancellable action delay")
		return
		
	print("Player: Action delay cancelled")
	_cancel_action_delay()


func _cancel_action_delay() -> void:
	action_delay_timer.stop()
	_on_action_delay_timeout()


func _on_action_delay_timeout() -> void:
	print("Player: Action delay completed")
	is_action_delayed = false
	action_delay_cancellable = false
	
	# Re-enable input
	player_controller.set_action_delay_active(false)
	movement_enabled = true
	rotation_enabled = true
	
	# Notify systems
	emit_signal("action_delay_completed")
