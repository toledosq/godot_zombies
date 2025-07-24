class_name InteractionComponent extends Area3D

signal interact(object)

@export var size: float = 2.0

var _nearby_interactables: Array[Node] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	# Check for button press
	if Input.is_action_just_pressed("interact"):
		_try_interact()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("interactable"):
		_nearby_interactables.append(body)

func _on_body_exited(body: Node) -> void:
	_nearby_interactables.erase(body)

func _try_interact() -> void:
	if _nearby_interactables.size() == 0:
		return
	
	# Pick first
	var target = _nearby_interactables[0]
	if target.has_method("interact"):
		target.interact()
	else:
		push_warning("%s has no interact method" % target.name)
