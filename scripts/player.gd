extends CharacterBody3D
class_name Player

@export var speed := 5.0

var previous_transform: Transform3D
var health_component: Health

signal player_health_changed(current: int, maximum: int)
signal player_died

@onready var body = $Body  # Path to visible mesh
@onready var collision = $CollisionShape3D


func _ready() -> void:
	health_component = $Health
	health_component.connect("health_changed", self._on_health_changed)
	health_component.connect("died", self._on_player_died)

func _physics_process(delta):
	previous_transform = body.global_transform
	_handle_movement(delta)
	_rotate_towards_mouse()

func _process(_delta: float) -> void:
	# Interpolate the body mesh movement to avoid ghosting from physics process
	var alpha = Engine.get_physics_interpolation_fraction()
	body.global_transform = previous_transform.interpolate_with(global_transform, alpha)
	
	# TEST: Press J to deal damage
	if Input.is_action_just_pressed("test_damage"):
		print(">>> Applying 10 damage")
		health_component.take_damage(10)
	# TEST: Press K to heal damage
	if Input.is_action_just_pressed("test_heal"):
		print(">>> Healing 5 HP")
		health_component.heal(5)

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
	# Update HUD
	emit_signal("player_health_changed", current, maximum)
	# Play hit flash
	print("Player: HP:", current, "/", maximum)

func _on_player_died() -> void:
	# Handle death: play animation, disable input, etc.
	emit_signal("player_died")
	print("Player: Player has died!")

func apply_damage(amount: int) -> void:
	health_component.take_damage(amount)

func apply_heal(amount: int) -> void:
	health_component.heal(amount)

func emit_current_health():
	print("Player: Sharing current health")
	emit_signal("player_health_changed", health_component.current_health, health_component.max_health)
