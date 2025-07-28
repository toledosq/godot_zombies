class_name HUDWeaponPanel extends HUDPanel


## OVERRIDE - The HUD Weapon Panels should not accept drops
func _can_drop_data(_position: Vector2, _data: Variant) -> bool:
	return false

func _drop_data(_position: Vector2, _data: Variant) -> void:
	pass

func _on_src_item_removed(_idx: int, _removed_item, _qty: int) -> void:
	pass
