extends Node3D

@export var camera_distance := 10.0
@export var camera_rotation := 60.0
@export var pan_limit := 3.0 # Maximum offset in meters
@export var pan_speed := 5.0 # Smooth movement speed
@export var target_node: Node3D

@onready var camera: Camera3D = $Camera3D

var initial_offset: Vector3
var player_height_offset: Vector3 = Vector3(0, -1.5, 0)
var current_pan_offset: Vector3 = Vector3.ZERO

func _ready():
	var pitch = deg_to_rad(camera_rotation)
	initial_offset = Vector3(0, sin(pitch), cos(pitch)) * camera_distance
	if target_node:
		set_target(target_node)

func _process(delta: float) -> void:
	if not target_node:
		return
	_update_position(delta)

func _update_position(delta: float) -> void:
	# Base position relative to target
	var target_pos = target_node.global_position + player_height_offset
	var desired_pos = target_pos + initial_offset
	
	# Get viewport size and mouse position
	var viewport_size = get_viewport().get_visible_rect().size
	var mouse_pos = get_viewport().get_mouse_position()
	
	# Calculate offset from center (-1 to 1)
	var offset_from_center = (mouse_pos - viewport_size * 0.5) / (viewport_size * 0.5)
	
	# Scale directly by pan_limit (no normalization)
	var pan_offset = Vector3(offset_from_center.x, 0, offset_from_center.y) * pan_limit
	pan_offset.y = 0  # Keep camera on XZ plane

	# Smoothly interpolate to new offset
	current_pan_offset = current_pan_offset.lerp(pan_offset, pan_speed * delta)

	# Apply offset to camera rig position
	global_position = desired_pos + current_pan_offset
	global_rotation = Vector3.ZERO


func set_target(target: Node3D):
	target_node = target
	global_position = target_node.global_position + initial_offset
	camera.look_at(target_node.global_position + player_height_offset, Vector3.UP)
