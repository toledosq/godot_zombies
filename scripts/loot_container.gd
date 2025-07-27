class_name LootContainer extends StaticBody3D

@onready var inv_comp: InventoryComponent = $InventoryComponent
@onready var interactable_bubble: Sprite3D = $InteractableBubble
var interactor: InteractionComponent
var fade_start: float = 10.0
var fade_end: float = 1.0


func _ready() -> void:
	inv_comp.max_slots = 5
	inv_comp.add_item(ItemDatabase.get_item("wep_mp5"), 2)
	interactable_bubble.visible = false

func _process(_delta: float) -> void:
	if interactor:
		var distance: float = (global_transform.origin).distance_to(interactor.global_transform.origin)
		var t = clamp((fade_start - distance) / (fade_start - fade_end), 0.0, 1.0)
		var col = interactable_bubble.modulate
		col.a = t
		interactable_bubble.modulate = col

func show_hint_bubble(interactor_: InteractionComponent, hint_visible_radius: float) -> void:
	interactor = interactor_
	fade_start = hint_visible_radius
	interactable_bubble.visible = true

func hide_hint_bubble() -> void: 
	interactor = null
	interactable_bubble.visible = false

func interact(interaction_component: Object) -> void:
	print(self, " : interacted with")
	if interaction_component.has_method("receive_inventory"):
		interaction_component.receive_inventory(inv_comp)
	else:
		push_warning("Passed-in interaction_component is missing receive_inventory()")
		print("LootContainer: handed off inventory")
