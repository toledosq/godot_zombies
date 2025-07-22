class_name InventorySlotUI extends Panel

@export var slot_index: int = 0

var inv_comp: InventoryComponent
var inventory: Inventory
var square_size = Vector2(64, 64)

@onready var icon: TextureRect = $Icon
@onready var count_label:Label = $Count


func _ready() -> void:
	# Force icon to be exactly 64×64
	icon.custom_minimum_size = square_size

	# Use aspect-preserving scaling (it’ll downscale large textures, but never stretch them)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func setup(component: InventoryComponent, inv: Inventory) -> void:
	inv_comp = component
	inventory = inv_comp.inventory
	
	# Listen for changes
	inv_comp.connect("item_added", Callable(self, "_on_inventory_changed"))
	inv_comp.connect("item_removed", Callable(self, "_on_inventory_changed"))
	inv_comp.connect("inventory_full", Callable(self, "_on_inventory_full"))
	
	refresh()


func refresh() -> void:
	# var slot = slot_index < inventory.slots.size() ? inventory.slots[slot_index] : null
	var slot = inventory.slots[slot_index] if slot_index < inventory.slots.size() else null
	
	if slot and slot.item and icon:
		icon.texture = slot.item.icon
		count_label.text = str(slot.quantity)
		tooltip_text = slot.item.display_name
	else:
		if icon:
			icon.texture = null
		else:
			print("No icon???")
		if count_label:
			count_label.text = ""
		tooltip_text = ""

func _on_inventory_changed(_item: ItemData, _qty: int) -> void:
	refresh()

# Drag & Drop hooks
func _get_drag_data(_position: Vector2) -> Variant:
	if slot_index >= inventory.slots.size(): return null
	var slot = inventory.slots[slot_index]
	if not slot.item: return null
	
	# Package the source index
	var data = { "from_index": slot_index }
	
	# Make drag preview
	var preview = TextureRect.new()
	preview.texture = icon.texture
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.custom_minimum_size = square_size
	set_drag_preview(preview)
	return data

func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("from_index")

func _drop_data(_position: Vector2, data: Variant) -> void:
	var from_idx = data["from_index"]
	var to_idx = slot_index
	print("Dropping data")
	inventory.swap_slots(from_idx, to_idx)
	
	# Tell UI to redraw
	inv_comp.emit_signal("item_removed", null, 0)
