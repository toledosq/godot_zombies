extends CanvasLayer
class_name PlayerHud

@onready var health_bar: ProgressBar = $BottomBar/CenterContainer/HBoxContainer/VitalsContainer/HealthBar
@onready var energy_bar: ProgressBar = $BottomBar/CenterContainer/HBoxContainer/VitalsContainer/EnergyBar
@onready var weapon_container: HBoxContainer = $BottomBar/CenterContainer/HBoxContainer/WeaponContainer
@onready var quick_slot_container: HBoxContainer = $BottomBar/CenterContainer/HBoxContainer/QuickSlotContainer


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

	# Resize Health Bars for screen %
	var bar_width = screen_size.x * 0.10
	var bar_height = screen_size.y * 0.05
	health_bar.custom_minimum_size = Vector2(bar_width, bar_height)
	energy_bar.custom_minimum_size = Vector2(bar_width, bar_height)
	
	# Resize Weapon Panels for screen %
	var square_size = screen_size.y * 0.10
	for square in weapon_container.get_children():
		square.custom_minimum_size = Vector2(square_size, square_size)
	
	# Resize Quick Slot Panels for screen %
	var element_size = screen_size.y * 0.05
	for element in weapon_container.get_children():
		element.custom_minimum_size = Vector2(element_size, element_size)

func _on_health_changed(_player_id: int, value: int, max_value: int):
	print("HUD: Player health changed")
	health_bar.max_value = max_value
	health_bar.value = value

func _on_player_died(_player_id):
	print("HUD: Player died!")
