# InteractionComponent.gd
class_name InteractionComponent
extends Node3D

@export var interaction_hint_visible_radius: float = 8.0
@export var interact_area_size: float = 1.5

# Track the actual components, not the bodies.
var _nearby_interactables: Array[InteractableComponent] = []
var _in_hint: Dictionary = {}       # body -> InteractableComponent
var _in_interact: Dictionary = {}   # body -> InteractableComponent

var container_inv_comp: InventoryComponent
var is_interacting := false

signal container_inventory_received(inventory_component: InventoryComponent)
signal container_inventory_closed()

@onready var interaction_area: Area3D = $InteractionArea
@onready var interaction_area_shape: CollisionShape3D = $InteractionArea/InteractionAreaShape

@onready var interaction_hint_area: Area3D = $InteractionHintArea
@onready var interaction_hint_area_shape: CollisionShape3D = $InteractionHintArea/InteractionHintAreaShape

func _ready() -> void:
	# Interact radius (ring on/off)
	interaction_area_shape.shape.radius = interact_area_size
	interaction_area.body_entered.connect(_on_body_entered_interaction_area)
	interaction_area.body_exited.connect(_on_body_exited_interaction_area)

	# Hint radius (bubble fade)
	interaction_hint_area_shape.shape.radius = interaction_hint_visible_radius
	interaction_hint_area.body_entered.connect(_on_body_entered_hint_area)
	interaction_hint_area.body_exited.connect(_on_body_exited_hint_area)

func _on_body_entered_interaction_area(body: Node) -> void:
	var comp := _get_interactable_from_body(body)
	if comp == null: return
	_in_interact[body] = comp
	if not _nearby_interactables.has(comp):
		_nearby_interactables.append(comp)
	comp.show_hint_ring()

func _on_body_exited_interaction_area(body: Node) -> void:
	var comp: InteractableComponent = _in_interact.get(body, null)
	if comp:
		comp.hide_hint_ring()
		_in_interact.erase(body)
		_nearby_interactables.erase(comp)

	# If you’re in an interaction UI with a container that just left range, close it.
	if container_inv_comp != null and body == container_inv_comp.get_parent():
		emit_signal("container_inventory_closed")
		container_inv_comp = null
		is_interacting = false

func _on_body_entered_hint_area(body: Node) -> void:
	var comp := _get_interactable_from_body(body)
	if comp == null: return
	_in_hint[body] = comp
	comp.show_hint_bubble(self, interaction_hint_visible_radius)

func _on_body_exited_hint_area(body: Node) -> void:
	var comp: InteractableComponent = _in_hint.get(body, null)
	if comp:
		comp.hide_hint_bubble()
		_in_hint.erase(body)

func _try_interact() -> void:
	if is_interacting:
		cancel_interaction()
		return
	if _nearby_interactables.is_empty():
		return

	var cam := get_viewport().get_camera_3d()
	if cam == null: return

	var mouse_pos := get_viewport().get_mouse_position()

	var closest: InteractableComponent = null
	var best_dist2 := INF
	for comp in _nearby_interactables:
		# Compare by screen‑space to the mouse (feels natural for gamepad+mouse setups)
		var screen_p := cam.unproject_position(comp.global_position)
		var d2 := screen_p.distance_squared_to(mouse_pos)
		if d2 < best_dist2:
			best_dist2 = d2
			closest = comp

	if closest and closest.has_method("interact"):
		closest.interact(self)
	else:
		push_warning("No valid interactable under cursor")

func cancel_interaction() -> void:
	if container_inv_comp != null:
		emit_signal("container_inventory_closed")
		container_inv_comp = null
		is_interacting = false

func receive_inventory(inventory_component: InventoryComponent) -> void:
	if container_inv_comp == inventory_component:
		return # already open
	container_inv_comp = inventory_component
	is_interacting = true
	emit_signal("container_inventory_received", container_inv_comp)


# --- helpers ---

func _get_interactable_from_body(body: Node) -> InteractableComponent:
	# Search descendants of the physics body for the InteractableComponent
	return _find_interactable_recursive(body)

func _find_interactable_recursive(node: Node) -> InteractableComponent:
	for c in node.get_children():
		if c is InteractableComponent:
			return c
		var found := _find_interactable_recursive(c)
		if found: return found
	return null
