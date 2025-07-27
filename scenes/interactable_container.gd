class_name InteractableContainer extends InteractableObject

@export var max_slots: int = 10
@export var collision_shape: Shape3D

@onready var inv_comp: InventoryComponent = $InventoryComponent

func _ready() -> void:
	if collision_shape:
		$CollisionShape3D.shape = collision_shape
	
	# parent _ready() already ran, so hints start hidden
	inv_comp.max_slots = max_slots
	inv_comp.add_item(ItemDatabase.get_item("wep_mp5"), 2)
	
	# connect the base "interacted" signal
	connect("interacted", Callable(self, "_on_interacted"))
	
	# Call super
	super._ready()

func _on_interacted(ic: Object) -> void:
	if ic.has_method("receive_inventory"):
		ic.receive_inventory(inv_comp)
	else:
		push_warning("Passed-in interaction_component is missing receive_inventory()")
