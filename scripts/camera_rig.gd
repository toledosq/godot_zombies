extends Node3D

@export var camera_distance := 10.0
@export var camera_rotation := 60.0
@export var target_node: Node3D

@onready var camera: Camera3D = $Camera3D

# Precomputed static offset direction
var initial_offset: Vector3
var player_height_offset: Vector3 = Vector3(0, -1.5, 0)

# Interpolation variables
var previous_transform: Transform3D

func _ready():
	# Make CameraRig ignore parent transforms
	set_as_top_level(true)
	
	# Compute the camera pitch vector just once
	var pitch = deg_to_rad(camera_rotation)
	initial_offset = Vector3(0, sin(pitch), cos(pitch)) * camera_distance

	if target_node:
		set_target(target_node)

func _physics_process(_delta: float) -> void:
	if not target_node:
		return
	
	# Store previous transform before updating
	previous_transform = global_transform
	
	_update_position()

func _process(_delta: float) -> void:
	if not target_node:
		return
	
	# Interpolate between physics ticks
	var alpha = Engine.get_physics_interpolation_fraction()
	global_transform = previous_transform.interpolate_with(global_transform, alpha)

func _update_position() -> void:
	# Desired camera rig position relative to target
	var target_pos = target_node.global_position + player_height_offset
	var desired_pos = target_pos + initial_offset

	# Update the rig's global transform directly
	global_position = desired_pos
	global_rotation = Vector3.ZERO  # Keep camera rig rotation fixed

	# Make camera look at the target with offset
	camera.look_at(target_pos, Vector3.UP)

func set_target(target):
	target_node = target
	# Snap rig and camera immediately to target
	global_position = target_node.global_position + initial_offset
	previous_transform = global_transform
	camera.look_at(target_node.global_position + player_height_offset, Vector3.UP)
