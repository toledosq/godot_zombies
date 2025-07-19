class_name PlayerCamera
extends Node3D

@export var smooth_speed := 20.0
@export var camera_distance := 10.0
@export var camera_rotation := 60.0
@export var deadzone_size := Vector2(0.3, 0.3)
@export var max_pan_distance_horizontal_x := 6.0
@export var max_pan_distance_horizontal_z := 3.0
@export var lerp_speed_min := 2.0
@export var lerp_speed_max := 5.0

# cache nodes once
@export var target_node: Node3D
@onready var camera: Camera3D    = $Camera3D

# precompute static offset direction
var initial_offset: Vector3

# reuse the same Plane for intersection tests
var pan_plane := Plane(Vector3.UP, 0.0)


func _ready():
	# compute the camera pitch vector just once
	var pitch = deg_to_rad(camera_rotation)
	initial_offset = Vector3(0, sin(pitch), cos(pitch)) * camera_distance

	if target_node:
		set_target(target_node)


func _process(delta):
	# Override inherited rotation
	global_rotation = Vector3.ZERO
	if not target_node:
		return

	# viewport & mouse
	var vp_size   = get_viewport().get_visible_rect().size
	var mouse_pos = get_viewport().get_mouse_position()
	var center    = vp_size * 0.5

	# deadzone math
	var dz_radius = vp_size * deadzone_size * 0.5
	var off       = mouse_pos - center
	var norm_off  = Vector2(off.x / dz_radius.x, off.y / dz_radius.y)
	var dist      = norm_off.length()
	var blend     = clamp((dist - 1.0) * 0.5, 0.0, 1.0)
	blend = ease(blend, 2.0)

	# target world‐pos and update plane height
	var tgt       = target_node.global_transform.origin
	pan_plane.d   = -tgt.y

	# raycast into horizontal plane
	var r_from    = camera.project_ray_origin(mouse_pos)
	var r_to      = r_from + camera.project_ray_normal(mouse_pos) * 1000.0
	var hit_point = pan_plane.intersects_ray(r_from, r_to)

	# desired pan position
	var desired = tgt
	if hit_point:
		# two‐step lerp for deadzone blending
		var mid = tgt.lerp(hit_point, 0.2)
		desired = tgt.lerp(mid, blend)

	# clamp on XZ
	desired.x = clamp(
		desired.x,
		tgt.x - max_pan_distance_horizontal_x,
		tgt.x + max_pan_distance_horizontal_x
	)
	desired.z = clamp(
		desired.z,
		tgt.z - max_pan_distance_horizontal_z,
		tgt.z + max_pan_distance_horizontal_z
	)
	desired.y = tgt.y

	# smooth follow
	var curr_pos  = global_transform.origin
	var speed_pct = lerp(lerp_speed_min, lerp_speed_max, delta * smooth_speed)
	var new_pos   = curr_pos.lerp(desired, speed_pct * delta)
	new_pos.y     = tgt.y  # re‑lock Y

	global_transform.origin = new_pos

func set_target(target):
	target_node = target
	camera.global_position = target_node.global_position + initial_offset
	camera.look_at(
		target_node.global_position + Vector3(0, -1.5, 0),
		Vector3.UP
	)
