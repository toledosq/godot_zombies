class_name HUDPanel extends Panel

@export var square_size: Vector2:
	set(val):
		square_size = val
		_refresh()
	get:
		return square_size

@onready var icon: TextureRect = $Icon
@onready var label: Label = $Label

var _src_comp: InventoryComponent = null
var _src_index := -1

func _ready() -> void:
	# Use aspect-preserving scaling (it’ll downscale large textures, but never stretch them)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	_refresh()

func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	if data is not Dictionary or not data.has("item"):
		return false
	if data.has("item") and data.item is WeaponData:
		return false
	return data["src_comp"].is_in_group("player_inventory")

func _drop_data(_position: Vector2, data: Variant) -> void:
	# disconnect any previous listener
	if _src_comp:
		_src_comp.disconnect("item_removed", _on_src_item_removed)
	
	# remember the new source
	_src_comp  = data["src_comp"]
	_src_index = data["src_index"]
	
	# listen for removals from that inventory
	_src_comp.connect("item_removed", _on_src_item_removed)
	
	# immediately display the dropped item
	var it = data["item"]
	set_icon_texture(it.icon)
	set_label_text(it.display_name)

# when the item is removed from its original inventory slot
func _on_src_item_removed(idx: int, _removed_item, _qty: int) -> void:
	if idx == _src_index:
		clear_icon_texture()
		clear_label_text()
		# no longer need to listen
		_src_comp.disconnect("item_removed", _on_src_item_removed)
		_src_comp = null
		_src_index = -1

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
	if icon:
		icon.custom_minimum_size = square_size
