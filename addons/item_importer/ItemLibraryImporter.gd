@tool
extends EditorScript

func _run():
	var json_path = "res://items/items.json"
	var json_file = FileAccess.open(json_path, FileAccess.READ)
	if not json_file:
		printerr("Could not open ", json_path)
		return
	var text = json_file.get_as_text()
	var data = JSON.parse_string(text)
	if data == null:
		printerr("Failed to parse items.json")
		return

	# Load or create the library
	var lib_path = "res://items/ItemLibrary.tres"
	if ResourceLoader.exists(lib_path):
		DirAccess.remove_absolute(lib_path)
	var library = ItemLibrary.new()
	library.items.clear()

	# Populate prototypes
	for entry in data:
		var proto = ItemData.new()
		
		proto.id = entry.get("id", "")
		proto.icon_file = entry.get("icon_file", "")
		proto.scene_file = entry.get("scene_file", "")
		proto.display_name = entry.get("display_name", "")
		proto.description = entry.get("description", "")
		proto.category = entry.get("category", "")
		proto.subcategory = entry.get("subcategory", "")
		proto.tags = entry.get("tags", "")
		proto.value = int(entry.get("value", 0))
		proto.weight = float(entry.get("weight", 0.0))
		proto.max_stack = int(entry.get("max_stack", 0))
		proto.sort_order = int(entry.get("sort_order", 0))
		proto.spawn_chance = float(entry.get("spawn_chance", 0.0))
		proto.equip_slot = entry.get("equip_slot", "")
		proto.durability_max = int(entry.get("durability_max", 0))
		proto.durability = int(entry.get("durability", 0))
		proto.dmg = int(entry.get("dmg", 0))
		proto.dmg_type = entry.get("dmg_type", "")
		proto.atk_speed = float(entry.get("atk_speed", 0.0))
		proto.atk_range = float(entry.get("atk_range", 0.0))
		proto.recoil = float(entry.get("recoil", 0.0))
		proto.ammo_type = entry.get("ammo_type", "")
		proto.mag_size = int(entry.get("mag_size", 0))
		proto.reload_time = float(entry.get("reload_time", 0.0))
		proto.armor_type = entry.get("armor_type", "")
		proto.resist_phys = float(entry.get("resist_phys", 0.0))
		proto.resist_fire = float(entry.get("resist_fire", 0.0))
		proto.consume_duration = float(entry.get("consume_duration", 0.0))
		proto.effect_type = entry.get("effect_type", "")
		proto.effect_value = int(entry.get("effect_value", 0))
		proto.effect_duration = float(entry.get("effect_duration", 0.0))
		proto.cooldown = float(entry.get("cooldown", 0.0))
		proto.craftable = entry.get("craftable", "")
		proto.recipe_id = entry.get("recipe_id", "")
		proto.recyclable = entry.get("recyclable", "")
		proto.recyclable_id = entry.get("recyclable_id", "")
		
		library.items.append(proto)

	# Save back to the same resource
	var err = ResourceSaver.save(library, lib_path)
	if err != OK:
		printerr("Failed to save ItemLibrary.tres: ", err)
	else:
		print("Imported ", library.items.size(), " items into ItemLibrary")
