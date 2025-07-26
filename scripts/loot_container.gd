class_name LootContainer extends StaticBody3D

@onready var inv_comp: InventoryComponent = $InventoryComponent
const prompt_scene = preload("uid://bdjynrr2iy3rp")
var prompt

func _ready() -> void:
	inv_comp.max_slots = 5
	inv_comp.add_item(ItemDatabase.get_item("wep_mp5"), 2)
	
	prompt = prompt_scene.instantiate()
	add_child(prompt)
	prompt.transform.origin = Vector3(0, 1.5, 0)
	prompt.visible = false

func show_prompt() -> void: 
	prompt.visible = true

func hide_prompt() -> void: 
	prompt.visible = false

func interact(interaction_component: Object) -> void:
	print(self, " : interacted with")
	if interaction_component.has_method("receive_inventory"):
		interaction_component.receive_inventory(inv_comp)
	else:
		push_warning("Passed-in interaction_component is missing receive_inventory()")
		print("LootContainer: handed off inventory")
