extends StaticBody3D

@onready var interactable_component: InteractableComponent = $InteractableComponent
@onready var loot_container: LootContainer = $LootContainer

func _ready() -> void:
	interactable_component.connect("interacted", loot_container._on_interacted)
