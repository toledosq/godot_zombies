class_name LootContainer extends StaticBody3D

@onready var inv_comp: InventoryComponent = $InventoryComponent
const INTERACT_PROMPT = preload("uid://bdjynrr2iy3rp")
var interact_prompt

func _ready() -> void:
	inv_comp.max_slots = 5
	inv_comp.add_item(ItemDatabase.get_item("wep_mp5"), 2)
	
	interact_prompt = INTERACT_PROMPT.instantiate()
	interact_prompt.visible = false

func show_prompt(): interact_prompt.visible = true

func hide_prompt(): interact_prompt.visible = false

func interact(interaction_component: Object) -> void:
	print(self, " : interacted with")
	if interaction_component.has_method("receive_inventory"):
		interaction_component.receive_inventory(inv_comp)
	else:
		push_warning("Passed-in interaction_component is missing receive_inventory()")
		print("LootContainer: handed off inventory")
