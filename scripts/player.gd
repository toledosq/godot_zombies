extends CharacterBody3D
class_name Player

@export var speed := 5.0

var player_id: int
var player_name: String

var previous_transform: Transform3D
var health_component: HealthComponent
var player_hud: PlayerHud

signal player_health_changed(player_id_:int, current: int, maximum: int)
signal player_died(player_id_: int)

@onready var body = $Body  # Path to visible mesh
@onready var collision = $CollisionShape3D
@onready var camera_rig = $PlayerCamera
@onready var inventory_component: InventoryComponent = $InventoryComponent


func _ready() -> void:
	# Connect player Health Component
	print("Player: Connecting Health Component")
	health_component = $HealthComponent
	health_component.connect("health_changed", _on_health_changed)
	health_component.connect("died", _on_player_died)
	
	# Connect player Heads Up Display
	print("Player: Connecting HUD")
	player_hud = $HUD
	connect("player_health_changed", player_hud._on_health_changed)
	connect("player_died", player_hud._on_player_died)
	emit_current_health()
	
	camera_rig.set_target(self)


func _physics_process(delta):
	_handle_movement(delta)
	_rotate_towards_mouse()


func _process(_delta: float) -> void:
	# TEST: Press J to deal damage
	if Input.is_action_just_pressed("test_damage"):
		print(">>> Applying 10 damage")
		health_component.take_damage(10)
	# TEST: Press K to heal damage
	if Input.is_action_just_pressed("test_heal"):
		print(">>> Healing 5 HP")
		health_component.heal(5)
	
	if Input.is_action_just_pressed("test_add_item"):
		print(">>> Adding 1 items")
		inventory_component.add_item(ItemDatabase.get_item("wep_mp5"), 1)
		
	if Input.is_action_just_pressed("test_remove_item"):
		print(">>> Removing 1 item")
		inventory_component.remove_item(ItemDatabase.get_item("wep_mp5"), 1)


func _handle_movement(delta):
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


func _rotate_towards_mouse():
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return

	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)

	# Project ray onto a horizontal plane at player's Y position
	var plane = Plane(Vector3.UP, global_transform.origin.y)
	var intersection = plane.intersects_ray(ray_origin, ray_dir)

	if intersection:
		var target_pos = intersection
		var direction = target_pos - global_transform.origin
		direction.y = 0  # Flatten direction to horizontal
		if direction.length() > 0.01:
			look_at(global_transform.origin + direction, Vector3.UP)


func _on_health_changed(current:int, maximum:int) -> void:
	# Announce health change
	emit_signal("player_health_changed", player_id, current, maximum)
	# Play hit flash
	print("Player: HP:", current, "/", maximum)


func _on_player_died() -> void:
	# Handle death: play animation, disable input, etc.
	emit_signal("player_died", player_id)
	print("Player: Player has died!")


func apply_damage(amount: int) -> void:
	health_component.take_damage(amount)


func apply_heal(amount: int) -> void:
	health_component.heal(amount)


func emit_current_health():
	print("Player: Sharing current health")
	_on_health_changed(health_component.current_health, health_component.max_health)


func pickup_item(item: ItemData, quantity: int) -> int:
	var result = inventory_component.add_item(item, quantity)
	if result.rejected > 0:
		print("Dropped %d %s because inventory full!" % [result.rejected, item.name])
		return result.rejected
	return 0
