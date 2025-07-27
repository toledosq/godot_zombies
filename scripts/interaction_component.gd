class_name InteractionComponent extends Node3D

@export var interaction_hint_visible_radius: float = 6.0
@export var interact_area_size: float = 2.5

var _nearby_interactables: Array[Node] = []
var container_inv_comp: InventoryComponent
var is_interacting := false

signal container_inventory_received(inventory_component: InventoryComponent)
signal container_inventory_closed()

@onready var interaction_area: Area3D = $InteractionArea
@onready var interaction_area_shape: CollisionShape3D = $InteractionArea/CollisionShape3D

@onready var interaction_hint_area: Area3D = $InteractionHintArea
@onready var interaction_hint_area_shape: CollisionShape3D = $InteractionHintArea/CollisionShape3D


func _ready() -> void:
	# Interaction Area
	interaction_area_shape.shape.radius = interact_area_size
	interaction_area.body_entered.connect(_on_body_entered_interaction_area)
	interaction_area.body_exited.connect(_on_body_exited_interaction_area)
	
	# Interaction Hint Area
	interaction_hint_area_shape.shape.radius = interaction_hint_visible_radius
	interaction_hint_area.body_entered.connect(_on_body_entered_hint_area)
	interaction_hint_area.body_exited.connect(_on_body_exited_hint_area)

func _on_body_entered_interaction_area(body: Node) -> void:
	if body.is_in_group("interactable"):
		_nearby_interactables.append(body)
		

func _on_body_exited_interaction_area(body: Node) -> void:
	if container_inv_comp != null and body == container_inv_comp.get_parent():
		print("InteractionComponent: Closing container inventory")
		emit_signal("container_inventory_closed")
		container_inv_comp = null
		is_interacting = false
		
	_nearby_interactables.erase(body)

func _on_body_entered_hint_area(body: Node) -> void:
	if body.is_in_group("interactable"):
		body.show_prompt()

func _on_body_exited_hint_area(body: Node) -> void:
	if body.is_in_group("interactable"):
		body.hide_prompt()

func _try_interact() -> void:
	if is_interacting:
		print("InteractionComponent: Canceling interaction")
		cancel_interaction()
		return
	
	if _nearby_interactables.size() == 0:
		return
	
	# Pick first
	var target = _nearby_interactables[0]
	if target.has_method("interact"):
		target.interact(self)
	else:
		push_warning("%s has no interact method" % target.name)

func cancel_interaction() -> void:
	if container_inv_comp != null:
		print("InteractionComponent: Manual cancel of interaction")
		emit_signal("container_inventory_closed")
		container_inv_comp = null
		is_interacting = false

func receive_inventory(inventory_component: InventoryComponent) -> void:
	if container_inv_comp == inventory_component:
		return # already have this inventory
		
	print("InteractionComponent: Received container inventory")
	container_inv_comp = inventory_component
	is_interacting = true
	emit_signal("container_inventory_received", container_inv_comp)
