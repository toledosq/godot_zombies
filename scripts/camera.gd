extends Camera3D

var previous_transform: Transform3D

func _physics_process(_delta: float) -> void:
# Store previous transform before updating
	previous_transform = global_transform
	
func _process(_delta) -> void:
	# Interpolate between physics ticks
	var alpha = Engine.get_physics_interpolation_fraction()
	global_transform = previous_transform.interpolate_with(global_transform, alpha)
