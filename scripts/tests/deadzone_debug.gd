extends Control

@export var deadzone_size: Vector2 = Vector2(0.3, 0.3)
@export var color: Color = Color(0, 1, 0, 0.3) # semi-transparent green
@export var border_thickness: float = 2.0
@export var segments: int = 64 # Higher = smoother ellipse

func _process(_delta):
	queue_redraw() # Request redraw every frame

func _draw():
	var viewport_size = get_viewport().get_visible_rect().size
	var screen_center = viewport_size * 0.5
	var radii = viewport_size * deadzone_size * 0.5

	# Draw outline ellipse (approximated with multiple segments)
	draw_arc_ellipse(screen_center, radii, color, border_thickness, segments)

# Custom helper function to draw ellipse using draw_arc
func draw_arc_ellipse(center: Vector2, radii: Vector2, color_: Color, thickness: float, segments_: int):
	var angle_step = TAU / segments_
	for i in range(segments_):
		var angle1 = i * angle_step
		var angle2 = (i + 1) * angle_step

		var point1 = center + Vector2(radii.x * cos(angle1), radii.y * sin(angle1))
		var point2 = center + Vector2(radii.x * cos(angle2), radii.y * sin(angle2))

		draw_line(point1, point2, color_, thickness)
