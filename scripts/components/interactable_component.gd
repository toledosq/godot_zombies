# InteractableComponent.gd
class_name InteractableComponent
extends Node3D

@export var hint_visible_radius: float = 10.0
@export var fade_start: float = 10.0
@export var fade_end: float = 1.5

@onready var hint_bubble: Sprite3D = $InteractHintGroup/HintBubble
@onready var hint_ring:   Sprite3D = $InteractHintGroup/HintRing

var interactor: Node3D = null
signal interacted(interactor: Node)

func _ready() -> void:
	add_to_group("interactable") # purely semantic; player won’t rely on this
	hint_bubble.visible = false
	hint_ring.visible   = false

func _process(_dt: float) -> void:
	if interactor:
		var d := global_position.distance_to(interactor.global_position)
		var denom: float = max(0.001, (fade_start - fade_end))
		var t: float = clamp((fade_start - d) / denom, 0.0, 1.0)
		hint_bubble.modulate.a = t

func show_hint_bubble(ic: Node3D, radius: float) -> void:
	interactor = ic
	fade_start = radius
	hint_bubble.visible = true

func hide_hint_bubble() -> void:
	interactor = null
	hint_bubble.visible = false

func show_hint_ring() -> void:
	hint_ring.visible = true

func hide_hint_ring() -> void:
	hint_ring.visible = false

func interact(ic: Object) -> void:
	emit_signal("interacted", ic)  # default behavior
