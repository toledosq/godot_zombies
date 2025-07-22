@tool
extends EditorScript

# Paths
const CSV_PATH := "res://data/ItemDB_20250721.csv"
const ITEM_LIBRARY_PATH := "res://data/ItemLibrary.tres"
const OUTPUT_DIR := "res://data/items/"

# Resource Classes
const BASE_ITEM_CLASS := preload("res://items/ItemData.gd")
const WEAPON_CLASS := preload("res://items/WeaponData.gd")
const ARMOR_CLASS := preload("res://items/ArmorData.gd")
const CONSUMABLE_CLASS := preload("res://items/ConsumableData.gd")

func _has_property(obj: Object, prop: String) -> bool:
	for dict in obj.get_property_list():
		if dict.get("name") == prop:
			return true
	return false

func _run():
	var csv_data = load_csv(CSV_PATH)
	var item_library = preload("res://items/ItemLibrary.gd").new()

	for row in csv_data:
		var item_type = row.get("category", "").to_lower()
		var item_resource
		match item_type:
			"weapon": 
				item_resource = WEAPON_CLASS.new()
			"armor": 
				item_resource = ARMOR_CLASS.new()
			"cons": 
				item_resource = CONSUMABLE_CLASS.new()
			_: 
				item_resource = BASE_ITEM_CLASS.new()

		# Assign common fields
		for key in row.keys():
			if not key.contains("."):
				if _has_property(item_resource, key):
					var parsed_value = parse_value(row[key])
					item_resource.set(key, parsed_value)
					print("Setting %s to %s" % [key, parsed_value])
					
		# Assign type-specific fields
		for key in row.keys():
			if key.begins_with("%s." % item_type):
				var field_name = key.replace("%s." % item_type, "")
				if _has_property(item_resource, field_name):
					item_resource.set(field_name, parse_value(row[key]))

		# Save Resource
		#var item_path = "%s%s.tres" % [OUTPUT_DIR, item_resource.name]
		#ResourceSaver.save(item_path, item_resource)
		
		item_library.items.append(item_resource)

	# Save ItemLibrary
	ResourceSaver.save(item_library, ITEM_LIBRARY_PATH)
	print("Item import completed: %s" % ITEM_LIBRARY_PATH)
	# Force reload
	item_library = ResourceLoader.load(
		ITEM_LIBRARY_PATH, "", ResourceLoader.CacheMode.CACHE_MODE_REPLACE
	)

	# If running in editor, rescan the filesystem:
	if Engine.is_editor_hint():
		var ep = EditorPlugin.new()
		ep.get_editor_interface().get_resource_filesystem().scan_sources()
		ep.free()

func load_csv(path: String) -> Array:
	var csv = FileAccess.open(path, FileAccess.READ)
	var lines = csv.get_as_text().split("\n")
	csv.close()

	var headers = lines[0].strip_edges().split(",")
	var data = []
	for i in range(1, lines.size()):
		var line = lines[i].strip_edges()
		if line == "":
			continue
		var values = line.split(",", true)
		var row = {}
		for j in range(headers.size()):
			row[headers[j]] = values[j] if j < values.size() else ""
		data.append(row)
	return data

func parse_value(value: String) -> Variant:
	value = value.strip_edges()
	if value == "":
		return ""
	if value.is_valid_float():
		return float(value)
	if value.is_valid_int():
		return int(value)
	if value.to_lower() in ["true", "false"]:
		return value.to_lower() == "true"
	return value
