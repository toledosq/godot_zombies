# InteractableObject.gd
class_name InteractableObject extends StaticBody3D


# how far away the bubble starts to fade, and when it’s fully opaque
@export var hint_visible_radius:  float = 10.0
@export var fade_start:			  float = 10.0
@export var fade_end:			  float =  1.5

@onready var hint_bubble: Sprite3D = $InteractHintGroup/InteractHintBubble
@onready var hint_ring:	  Sprite3D = $InteractHintGroup/InteractHintRing

# the thing doing the interacting
var interactor: InteractionComponent = null

signal interacted(interactor)

func _ready() -> void:
	hint_bubble.visible = false
	hint_ring.visible	= false

func _process(_delta: float) -> void:
	if interactor:
		var d = global_transform.origin.distance_to(interactor.global_transform.origin)
		var t = clamp((fade_start - d) / (fade_start - fade_end), 0.0, 1.0)
		hint_bubble.modulate.a = t

func show_hint_bubble(ic: InteractionComponent, radius: float) -> void:
	interactor	  = ic
	fade_start	  = radius
	hint_bubble.visible = true

func hide_hint_bubble() -> void:
	interactor = null
	hint_bubble.visible = false

func show_hint_ring() -> void:
	hint_ring.visible = true

func hide_hint_ring() -> void:
	hint_ring.visible = false

func interact(ic: Object) -> void:
	# default behavior: emit a signal
	emit_signal("interacted", ic)
