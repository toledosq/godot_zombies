class_name PlayerHud extends CanvasLayer

signal ready_

var default_crosshair_texture: Texture2D = preload("res://assets/icons/generic_button_circle_outline.png")
@export var crosshair_texture: Texture2D

@onready var bottom_bar: Control = $BottomBar
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

# Active weapon slot tracking
var current_active_slot: int = 0  # Track which weapon slot is currently active

# Reference resolution for scaling calculations (1920x1080)
const REFERENCE_WIDTH = 1920.0
const REFERENCE_HEIGHT = 1080.0


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
	
	# Initialize the active weapon slot visual feedback (slot 0 is default active)
	call_deferred("_initialize_active_slot")
	
	# Debug: Print initial viewport size
	var initial_size = get_viewport().get_visible_rect().size
	print("HUD: Initial viewport size: %dx%d" % [initial_size.x, initial_size.y])
	
	# Init crosshair
	if not crosshair_texture:
		crosshair_texture = default_crosshair_texture
	
	# Announce ready status
	print("HUD: Ready")
	emit_signal("ready_")

func _on_weapon_equipped(slot_idx: int, weapon_data: WeaponData):
	print("HUD: weapon equipped to slot %d" % slot_idx)
	var panel: HUDWeaponPanel = weapon_container.get_child(slot_idx) as HUDWeaponPanel
	panel.set_icon_texture(weapon_data.icon)
	# Set initial ammo display
	panel.set_weapon_ammo(weapon_data.current_ammo, weapon_data.mag_size)

func _on_weapon_unequipped(slot_idx: int):
	print("HUD: weapon unequipped from slot %d" % slot_idx)
	var panel: HUDWeaponPanel = weapon_container.get_child(slot_idx) as HUDWeaponPanel
	panel.clear_weapon()

func _on_ammo_changed(slot_idx: int, current_ammo: int, max_ammo: int) -> void:
	print("HUD: Ammo changed for slot %d: %d/%d" % [slot_idx, current_ammo, max_ammo])
	# Ensure slot index is valid
	if slot_idx < 0 or slot_idx >= weapon_container.get_child_count():
		print("HUD: Invalid weapon slot index for ammo update: %d" % slot_idx)
		return
	
	var panel: HUDWeaponPanel = weapon_container.get_child(slot_idx) as HUDWeaponPanel
	if panel:
		panel.set_weapon_ammo(current_ammo, max_ammo)
	else:
		print("HUD: Could not find weapon panel for ammo update at slot %d" % slot_idx)

func _update_hud_layout():
	"""
	Updates the HUD layout for the current viewport size.
	Uses 1920x1080 as reference resolution for consistent scaling.
	"""
	var screen_size = get_viewport().get_visible_rect().size
	print("HUD: Updating layout for resolution: %dx%d" % [screen_size.x, screen_size.y])
	
	# Calculate scaling factors based on reference resolution
	var scale_x = screen_size.x / REFERENCE_WIDTH
	var scale_y = screen_size.y / REFERENCE_HEIGHT
	var scale_factor = min(scale_x, scale_y)  # Use minimum to maintain aspect ratio
	
	# Prevent HUD from becoming too small on very low resolutions
	scale_factor = max(scale_factor, 0.5)  # Minimum 50% of reference size
	
	# Update BottomBar positioning and size
	_update_bottom_bar_layout(screen_size, scale_factor)
	
	# Update component sizes with proper scaling
	_update_vitals_layout(scale_factor)
	_update_weapon_slots_layout(scale_factor)
	_update_quick_slots_layout(scale_factor)


func _update_bottom_bar_layout(screen_size: Vector2, scale_factor: float) -> void:
	"""
	Updates the BottomBar control's position and size to properly anchor it above the viewport bottom.
	"""
	if not bottom_bar:
		print("HUD: Warning - bottom_bar reference is null")
		return
	
	# Calculate bar height based on content (at reference resolution: ~120px total height)
	# Health bars: 48px, weapon slots: 108px, padding: ~20px = ~120px total
	var bar_height = 120.0 * scale_factor
	var bottom_margin = 20.0 * scale_factor  # Small offset from viewport bottom
	
	# Set anchors for bottom-center positioning
	bottom_bar.anchor_left = 0.5
	bottom_bar.anchor_right = 0.5
	bottom_bar.anchor_top = 1.0
	bottom_bar.anchor_bottom = 1.0
	
	# Calculate proper offsets to center horizontally and position above bottom
	var bar_width = 600.0 * scale_factor  # Estimated total width at reference resolution
	
	# Ensure the bar fits within the screen width
	var max_bar_width = screen_size.x * 0.95  # Use 95% of screen width maximum
	bar_width = min(bar_width, max_bar_width)
	
	bottom_bar.offset_left = -bar_width / 2.0
	bottom_bar.offset_right = bar_width / 2.0
	bottom_bar.offset_top = -(bar_height + bottom_margin)
	bottom_bar.offset_bottom = -bottom_margin
	
	print("HUD: BottomBar positioned - height: %.1f, margin: %.1f" % [bar_height, bottom_margin])


func _update_vitals_layout(scale_factor: float) -> void:
	"""
	Updates health and energy bar sizes based on scaling factor.
	"""
	# At reference resolution: health/energy bars are ~192x48px each
	var bar_width = 192.0 * scale_factor
	var bar_height = 48.0 * scale_factor
	
	var bar_size = Vector2(bar_width, bar_height)
	health_bar.custom_minimum_size = bar_size
	energy_bar.custom_minimum_size = bar_size


func _update_weapon_slots_layout(scale_factor: float) -> void:
	"""
	Updates weapon slot panel sizes based on scaling factor.
	"""
	# At reference resolution: weapon slots are ~108x108px each
	var slot_size = 108.0 * scale_factor
	var square_size = Vector2(slot_size, slot_size)
	
	for panel in weapon_container.get_children():
		# All Control nodes have custom_minimum_size property
		panel.custom_minimum_size = square_size
		# HUDPanel has square_size property for internal scaling
		if "square_size" in panel:
			panel.square_size = square_size


func _update_quick_slots_layout(scale_factor: float) -> void:
	"""
	Updates quick slot panel sizes based on scaling factor.
	"""
	# At reference resolution: quick slots are ~54x54px each  
	var slot_size = 54.0 * scale_factor
	var square_size = Vector2(slot_size, slot_size)
	
	for panel in quick_slot_container.get_children():
		# All Control nodes have custom_minimum_size property
		panel.custom_minimum_size = square_size
		# HUDPanel has square_size property for internal scaling
		if "square_size" in panel:
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

func _on_active_weapon_changed(slot_idx: int, weapon_data: WeaponData) -> void:
	# Update the active slot tracking and visual feedback
	# This works even if weapon_data is null (empty slot)
	_update_active_weapon_slot(slot_idx)
	
	# Future: Swap the crosshair texture based on weapon
	# if weapon_data:
	#     set_crosshair_texture(weapon_data.crosshair)
	# else:
	#     set_crosshair_texture(default_crosshair_texture)

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


# Active weapon slot visual feedback system
func _update_active_weapon_slot(new_active_slot: int) -> void:
	"""
	Updates the visual feedback for the active weapon slot.
	Removes the orange border from the previous active slot and adds it to the new active slot.
	"""
	print("HUD: Updating active weapon slot from %d to %d" % [current_active_slot, new_active_slot])
	
	# Remove active border from previous slot
	_set_weapon_slot_active(current_active_slot, false)
	
	# Add active border to new slot
	_set_weapon_slot_active(new_active_slot, true)
	
	# Update tracking variable
	current_active_slot = new_active_slot


func _set_weapon_slot_active(slot_idx: int, is_active: bool) -> void:
	"""
	Sets the active visual state for a specific weapon slot.
	Adds or removes an orange border to indicate the active slot.
	"""
	# Check if weapon_container exists
	if not weapon_container:
		print("HUD: weapon_container is null, cannot set active slot")
		return
	
	# Ensure the slot index is valid
	if slot_idx < 0 or slot_idx >= weapon_container.get_child_count():
		print("HUD: Invalid weapon slot index: %d (total children: %d)" % [slot_idx, weapon_container.get_child_count()])
		return
	
	# Get the weapon panel for this slot
	var panel: Panel = weapon_container.get_child(slot_idx) as Panel
	if not panel:
		print("HUD: Could not find weapon panel for slot %d" % slot_idx)
		return
	
	print("HUD: Found panel of type: %s for slot %d" % [panel.get_class(), slot_idx])
	
	# Apply or remove the active border styling
	if is_active:
		# Add orange border to indicate active slot
		panel.add_theme_stylebox_override("panel", _create_active_slot_style())
		print("HUD: Added active border to weapon slot %d" % slot_idx)
	else:
		# Remove the border styling (return to default)
		panel.remove_theme_stylebox_override("panel")
		print("HUD: Removed active border from weapon slot %d" % slot_idx)


func _create_active_slot_style() -> StyleBox:
	"""
	Creates a StyleBox with an orange border for the active weapon slot.
	This provides clear visual feedback about which slot is currently active.
	"""
	var style = StyleBoxFlat.new()
	
	# Set orange border properties
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color.ORANGE
	
	# Make the background transparent so only the border shows
	style.bg_color = Color.TRANSPARENT
	
	return style


func _initialize_active_slot() -> void:
	"""
	Initializes the active weapon slot visual feedback after the HUD is fully set up.
	This is called deferred to ensure all child nodes are ready.
	"""
	# Check if weapon_container has children before initializing
	if not weapon_container or weapon_container.get_child_count() == 0:
		print("HUD: Weapon container not ready yet, retrying initialization...")
		call_deferred("_initialize_active_slot")
		return
	
	# Set the initial active slot (slot 0) with visual feedback
	_set_weapon_slot_active(current_active_slot, true)
	print("HUD: Initialized active weapon slot %d with visual feedback" % current_active_slot)


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
