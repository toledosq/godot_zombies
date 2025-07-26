class_name InteractionComponent extends Area3D

@export var size: float = 2.0

var _nearby_interactables: Array[Node] = []
var container_inv_comp: InventoryComponent
var is_interacting := false

signal container_inventory_received(inventory_component: InventoryComponent)
signal container_inventory_closed()

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("interactable"):
		_nearby_interactables.append(body)
		body.show_prompt()

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("interactable"):
		body.hide_prompt()
		
	if container_inv_comp != null and body == container_inv_comp.get_parent():
		print("InteractionComponent: Closing container inventory")
		emit_signal("container_inventory_closed")
		container_inv_comp = null
		is_interacting = false
		
	_nearby_interactables.erase(body)

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
