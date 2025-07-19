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
		proto.id            = entry.get("id", "")
		proto.display_name  = entry.get("name", "")
		proto.description   = entry.get("description", "")
		proto.value         = int(entry.get("value", 0))
		# … map any other fields your sheet defines …
		library.items.append(proto)

	# Save back to the same resource
	var err = ResourceSaver.save(library, lib_path)
	if err != OK:
		printerr("Failed to save ItemLibrary.tres: ", err)
	else:
		print("Imported ", library.items.size(), " items into ItemLibrary")
