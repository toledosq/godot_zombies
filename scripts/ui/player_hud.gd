class_name PlayerHud extends CanvasLayer

signal ready_

var default_crosshair_texture: Texture2D = preload("res://assets/icons/generic_button_circle_outline.png")
@export var crosshair_texture: Texture2D

@onready var health_bar: ProgressBar = $BottomBar/CenterContainer/HBoxContainer/VitalsContainer/HealthBar
@onready var energy_bar: ProgressBar = $BottomBar/CenterContainer/HBoxContainer/VitalsContainer/EnergyBar
@onready var weapon_container: HBoxContainer = $BottomBar/CenterContainer/HBoxContainer/WeaponContainer
@onready var quick_slot_container: HBoxContainer = $BottomBar/CenterContainer/HBoxContainer/QuickSlotContainer
@onready var action_delay_container: VBoxContainer = $CenterContainer/ActionDelayContainer
@onready var action_delay_progress: ProgressBar = $CenterContainer/ActionDelayContainer/ActionDelayProgressBar
@onready var action_delay_label: Label = $CenterContainer/ActionDelayContainer/ActionDelayLabel

# Action delay state
var action_delay_timer: Timer
var action_delay_total_time: float
var action_delay_is_cancellable: bool


func _ready():
	# Setup action delay timer
	action_delay_timer = Timer.new()
	action_delay_timer.wait_time = 0.1  # Update every 0.1 seconds
	action_delay_timer.timeout.connect(_update_action_delay_progress)
	add_child(action_delay_timer)
	
	# Hide action delay container initially
	if action_delay_container:
		action_delay_container.visible = false
	
	# Initial setup
	_update_hud_layout()

	# Connect to viewport resize for dynamic scaling
	get_viewport().connect("size_changed", _update_hud_layout)
	
	# Init crosshair
	if not crosshair_texture:
		crosshair_texture = default_crosshair_texture
	
	# Announce ready status
	print("HUD: Ready")
	emit_signal("ready_")

func _on_weapon_equipped(slot_idx: int, weapon_data: WeaponData):
	print("HUD: weapon equipped to slot %d" % slot_idx)
	var panel: HUDPanel = weapon_container.get_child(slot_idx)
	panel.set_icon_texture(weapon_data.icon)

func _on_weapon_unequipped(slot_idx: int):
	print("HUD: weapon unequipped from slot %d" % slot_idx)
	var panel = weapon_container.get_child(slot_idx)
	panel.clear_icon_texture()

func _update_hud_layout():
	var screen_size = get_viewport().get_visible_rect().size

	# Resize Health Bars for screen %
	var bar_width = screen_size.x * 0.10
	var bar_height = screen_size.y * 0.05
	health_bar.custom_minimum_size = Vector2(bar_width, bar_height)
	energy_bar.custom_minimum_size = Vector2(bar_width, bar_height)
	
	# Resize Weapon Panels for screen %
	var square_size = Vector2(screen_size.y * 0.10, screen_size.y * 0.10)
	for panel in weapon_container.get_children():
		panel.custom_minimum_size = square_size
		panel.square_size = square_size
	
	# Resize Quick Slot Panels for screen %
	square_size = Vector2(screen_size.y * 0.05, screen_size.y * 0.05)
	for panel in quick_slot_container.get_children():
		panel.custom_minimum_size = square_size
		panel.square_size = square_size

func _on_health_changed(_player_id: int, value: int, max_value: int):
	print("HUD: Player health changed")
	health_bar.max_value = max_value
	health_bar.value = value

func _on_energy_changed(_player_id: int, value: int, max_value: int):
	energy_bar.max_value = max_value
	energy_bar.value = value

func _on_player_died(_player_id):
	print("HUD: Player died!")

func _on_active_weapon_changed(_slot_idx: int, _weapon_data: WeaponData) -> void:
	# 1) Swap the crosshair texture
	# set_crosshair_texture(weapon_data.crosshair)
	pass

func _on_mouse_mode_changed(mode: Input.MouseMode) -> void:
	match mode:
		Input.MOUSE_MODE_CONFINED:
			Input.set_custom_mouse_cursor(crosshair_texture, Input.CURSOR_ARROW, crosshair_texture.get_size() / 2)
		Input.MOUSE_MODE_VISIBLE:
			Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)

func set_crosshair_texture(tex: Texture2D):
	crosshair_texture = tex
	# Call this to ensure the crosshair updates
	_on_mouse_mode_changed(Input.mouse_mode)


# Action delay system
func _on_action_delay_started(seconds: float, cancellable: bool) -> void:
	print("HUD: Action delay started - %s seconds, cancellable: %s" % [seconds, cancellable])
	action_delay_total_time = seconds
	action_delay_is_cancellable = cancellable
	
	# Setup progress bar
	if action_delay_progress:
		action_delay_progress.max_value = seconds
		action_delay_progress.value = seconds
	
	# Setup label
	if action_delay_label:
		var label_text = "Action in progress... (%.1fs)" % seconds
		if cancellable:
			label_text += " - Press ESC to cancel"
		action_delay_label.text = label_text
	
	# Show container and start timer
	if action_delay_container:
		action_delay_container.visible = true
	action_delay_timer.start()


func _on_action_delay_completed() -> void:
	print("HUD: Action delay completed")
	_hide_action_delay()


func _on_action_delay_cancelled() -> void:
	print("HUD: Action delay cancelled")
	_hide_action_delay()


func _hide_action_delay() -> void:
	if action_delay_container:
		action_delay_container.visible = false
	action_delay_timer.stop()


func _update_action_delay_progress() -> void:
	if not action_delay_progress or not action_delay_container.visible:
		return
	
	# Update progress bar value (countdown)
	var current_value = action_delay_progress.value - 0.1
	if current_value <= 0:
		current_value = 0
		action_delay_timer.stop()
	
	action_delay_progress.value = current_value
	
	# Update label with remaining time
	if action_delay_label:
		var label_text = "Action in progress... (%.1fs)" % current_value
		if action_delay_is_cancellable:
			label_text += " - Press ESC to cancel"
		action_delay_label.text = label_text
