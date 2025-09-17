class_name HUDWeaponPanel extends HUDPanel

# Store ammo info for this weapon slot
var current_ammo: int = 0
var max_ammo: int = 0

## OVERRIDE - The HUD Weapon Panels should not accept drops
func _can_drop_data(_position: Vector2, _data: Variant) -> bool:
	return false

func _drop_data(_position: Vector2, _data: Variant) -> void:
	pass

func _on_src_item_removed(_idx: int, _removed_item, _qty: int) -> void:
	pass

func set_weapon_ammo(current: int, maximum: int) -> void:
	current_ammo = current
	max_ammo = maximum
	update_ammo_display()

func update_ammo_display() -> void:
	if max_ammo > 0:
		# Display ammo count for ranged weapons
		set_label_text("%d/%d" % [current_ammo, max_ammo])
	else:
		# Clear ammo display for melee weapons or empty slots
		clear_label_text()

func clear_weapon() -> void:
	current_ammo = 0
	max_ammo = 0
	clear_icon_texture()
	clear_label_text()
