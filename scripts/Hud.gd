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

func _on_weapon_equipped(slot_idx: int, weapon_data: WeaponData):
	var panel: Panel = weapon_container.get_child(slot_idx)
	#panel.icon.texture = weapon_data.icon_texture

func _on_weapon_unequipped(slot_idx: int):
	var panel = weapon_container.get_child(slot_idx)
	#panel.icon.texture = null

func _update_hud_layout():
	var screen_size = get_viewport().get_visible_rect().size

	# Resize Health Bars for screen %
	var bar_width = screen_size.x * 0.10
	var bar_height = screen_size.y * 0.05
	health_bar.custom_minimum_size = Vector2(bar_width, bar_height)
	energy_bar.custom_minimum_size = Vector2(bar_width, bar_height)
	
	# Resize Weapon Panels for screen %
	var element_size = screen_size.y * 0.10
	for element in weapon_container.get_children():
		element.custom_minimum_size = Vector2(element_size, element_size)
	
	# Resize Quick Slot Panels for screen %
	element_size = screen_size.y * 0.05
	for element in weapon_container.get_children():
		element.custom_minimum_size = Vector2(element_size, element_size)

func _on_health_changed(_player_id: int, value: int, max_value: int):
	print("HUD: Player health changed")
	health_bar.max_value = max_value
	health_bar.value = value

func _on_energy_changed(_player_id: int, value: int, max_value: int):
	energy_bar.max_value = max_value
	energy_bar.value = value

func _on_player_died(_player_id):
	print("HUD: Player died!")

func _on_active_weapon_changed(slot_idx: int, weapon_data: WeaponData) -> void:
	# 1) Swap the icon texture
	var panel = weapon_container.get_child(slot_idx)
	panel.icon.texture = weapon_data.icon_texture
	
	# 2) Update the colored border
	for i in weapon_container.get_child_indices():
		var p = weapon_container.get_child(i)
		# For StyleBoxFlat borders, you can do:
		var style = p.get("custom_styles/panel")
		style.border_width_left  = 4 if (i == slot_idx) else 0
		style.border_width_top   = 4 if (i == slot_idx) else 0
		style.border_width_right = 4 if (i == slot_idx) else 0
		style.border_width_bottom= 4 if (i == slot_idx) else 0
		style.border_color       = Color.ORANGE_RED
		p.add_theme_stylebox_override("panel", style)
