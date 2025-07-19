extends CanvasLayer
class_name PlayerHud

@onready var vitals_container = $VitalsContainer
@onready var health_bar = $VitalsContainer/HealthBar

signal ready_

func _ready():
	# Initial setup
	_update_hud_layout()

	# Connect to viewport resize for dynamic scaling
	get_viewport().connect("size_changed", _update_hud_layout)
	
	# Announce ready status
	print("HUD: Ready")
	emit_signal("ready_")

func _update_hud_layout():
	var screen_size = get_viewport().get_visible_rect().size

	# --- VitalsContainer: Full Rect ---
	vitals_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	vitals_container.offset_left = 0
	vitals_container.offset_top = 0
	vitals_container.offset_right = 0
	vitals_container.offset_bottom = 0

	# --- HealthBar ---
	# Anchor to bottom left
	health_bar.set_anchors_preset(Control.PRESET_BOTTOM_LEFT, false)

	# Padding (2% of screen size)
	var padding_x = screen_size.x * 0.04
	var padding_y = screen_size.y * 0.04

	health_bar.offset_left = padding_x
	health_bar.offset_bottom = -padding_y
	health_bar.offset_top = 0
	health_bar.offset_right = 0

	# Size (10% of screen width)
	var bar_width = screen_size.x * 0.15
	var bar_height = screen_size.y * 0.04
	health_bar.custom_minimum_size = Vector2(bar_width, bar_height)

func _on_health_changed(_player_id: int, value: int, max_value: int):
	print("HUD: Player health changed")
	health_bar.max_value = max_value
	health_bar.value = value

func _on_player_died(_player_id):
	print("HUD: Player died!")
