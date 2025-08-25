extends Node3D

@export var camera_distance := 12.0
@export var camera_rotation := 60.0
@export var pan_limit := 3.0 # Maximum offset in meters
@export var aim_pan_limit := 6.0 # Maximum offset in meters when aiming
@export var pan_speed := 5.0 # Smooth movement speed
@export var target_node: Node3D

# Aiming properties
@export var aim_fov := 65.0 # FOV when aiming (narrower than default 75)
var default_fov: float
var is_aiming := false
var aim_transition_speed := 8.0 # Speed of FOV transition

@onready var camera: Camera3D = $Camera3D

var initial_offset: Vector3
var player_height_offset: Vector3 = Vector3(0, -1.5, 0)
var current_pan_offset: Vector3 = Vector3.ZERO

func _ready():
	var pitch = deg_to_rad(camera_rotation)
	initial_offset = Vector3(0, sin(pitch), cos(pitch)) * camera_distance
	default_fov = camera.fov
	if target_node:
		set_target(target_node)

func _process(delta: float) -> void:
	if not target_node:
		return
	_update_position(delta)
	_update_aiming(delta)
	force_update_transform()

func _update_position(delta: float) -> void:
	# Base position relative to target
	var target_pos = target_node.global_position + player_height_offset
	var desired_pos = target_pos + initial_offset
	
	# Get viewport size and mouse position
	var viewport_size = get_viewport().get_visible_rect().size
	var mouse_pos = get_viewport().get_mouse_position()
	
	# Calculate offset from center (-1 to 1)
	var offset_from_center = (mouse_pos - viewport_size * 0.5) / (viewport_size * 0.5)
	
	# Scale by pan_limit, with increased limit when aiming
	var current_pan_limit = aim_pan_limit if is_aiming else pan_limit
	var pan_offset = Vector3(offset_from_center.x, 0, offset_from_center.y) * current_pan_limit
	pan_offset.y = 0  # Keep camera on XZ plane

	# Smoothly interpolate to new offset
	current_pan_offset = current_pan_offset.lerp(pan_offset, pan_speed * delta)

	# Apply offset to camera rig position
	global_position = desired_pos + current_pan_offset
	global_rotation = Vector3.ZERO


func _update_aiming(delta: float) -> void:
	# Smoothly transition FOV based on aiming state
	var target_fov = aim_fov if is_aiming else default_fov
	camera.fov = lerp(camera.fov, target_fov, aim_transition_speed * delta)

func set_aiming(aiming: bool) -> void:
	if is_aiming != aiming:
		print("CameraRig: Aiming = %s" % aiming)
		is_aiming = aiming

func set_target(target: Node3D):
	target_node = target
	global_position = target_node.global_position + initial_offset
	camera.look_at(target_node.global_position + player_height_offset, Vector3.UP)
