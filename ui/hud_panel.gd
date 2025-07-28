class_name HUDPanel extends Panel

@export var square_size: Vector2:
	set(val):
		square_size = val
		_refresh()
	get:
		return square_size

@onready var icon: TextureRect = $Icon
@onready var label: Label = $Label

func _ready() -> void:
	# Use aspect-preserving scaling (it’ll downscale large textures, but never stretch them)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	_refresh()

func set_icon_texture(tex: Texture2D) -> void:
	icon.texture = tex

func clear_icon_texture() -> void:
	icon.texture = null

func set_label_text(text: String) -> void:
	label.text = text

func clear_label_text() -> void:
	label.text = ""

func _refresh() -> void:
	# Force icon to be specific size
	icon.custom_minimum_size = square_size
