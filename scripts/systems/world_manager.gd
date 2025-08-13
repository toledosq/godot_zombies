extends Node
class_name WorldManager

signal world_loaded(world_root: Node)
signal world_unloaded()
signal player_spawned(player: Node)

@export var world_parent_path: NodePath = NodePath("")	# leave empty to use owner (Game)
@export var actors_subpath: NodePath = NodePath("Actors") # looked up inside world root
@export var fallback_origin := Transform3D()

var _world_root: Node = null
var _player: Node = null

func _get_world_parent() -> Node:
	if world_parent_path.is_empty():
		return get_parent()	 # default: attach world under Game
	return get_node(world_parent_path)

# ---------- World lifecycle ----------

func load_world(world_scene: PackedScene) -> void:
	await unload_world()

	var parent := _get_world_parent()
	_world_root = world_scene.instantiate()
	parent.add_child(_world_root)
	_world_root.owner = parent.owner  # keep ownership tidy for saving, if needed

	emit_signal("world_loaded", _world_root)

func unload_world() -> void:
	if not _world_root:
		return
	# Clean up player (detach) to avoid freeing it with world unless you *want* to.
	if is_instance_valid(_player) and _player.get_parent() == _world_root:
		_player.get_parent().remove_child(_player)
		add_child(_player)	# park the player temporarily (or queue_free, your choice)

	_world_root.queue_free()
	_world_root = null
	emit_signal("world_unloaded")

# ---------- Spawn helpers ----------

func _find_actors_container() -> Node:
	if not _world_root:
		return null
	if actors_subpath.is_empty():
		return _world_root
	return _world_root.get_node_or_null(actors_subpath)

func _get_spawn_transform(spawn_tag := "default") -> Transform3D:
	# Strategy:
	# 1) First node in group "player_spawn" that matches a "tag" (by name suffix), else any.
	# 2) Else Marker3D named "PlayerSpawn".
	# 3) Else world origin (fallback).
	if _world_root:
		var spawns := _world_root.get_tree().get_nodes_in_group("player_spawn")
		for s in spawns:
			if not (s is Node3D):
				continue
			if spawn_tag == "default" or s.name.to_lower().contains(spawn_tag.to_lower()):
				return (s as Node3D).global_transform

		var marker := _world_root.get_node_or_null("PlayerSpawn")
		if marker is Marker3D:
			return (marker as Marker3D).global_transform

	return fallback_origin

# ---------- Player control ----------

func spawn_player(player_scene: PackedScene, spawn_tag := "default") -> Node:
	# If you prefer “one player instance per game session”, create it once and move it around.
	if not is_instance_valid(_player):
		_player = player_scene.instantiate()
	var actors := _find_actors_container()
	if _player.get_parent() != actors:
		if is_instance_valid(_player.get_parent()):
			_player.get_parent().remove_child(_player)
		actors.add_child(_player)

	# Place at spawn:
	var xform := _get_spawn_transform(spawn_tag)
	if _player is Node3D:
		(_player as Node3D).global_transform = xform
	else:
		# 2D fallback:
		if _player.has_method("set_global_position"):
			_player.call("set_global_position", xform.origin)

	emit_signal("player_spawned", _player)
	return _player

func respawn_player(spawn_tag := "default") -> Node:
	# Keep existing player instance; just move it to a new spawn in the current world.
	if not is_instance_valid(_player):
		push_warning("respawn_player called but no player exists; did you mean spawn_player?")
		return null

	var actors := _find_actors_container()
	if _player.get_parent() != actors:
		if is_instance_valid(_player.get_parent()):
			_player.get_parent().remove_child(_player)
		actors.add_child(_player)

	var xform := _get_spawn_transform(spawn_tag)
	if _player is Node3D:
		(_player as Node3D).global_transform = xform
	else:
		if _player.has_method("set_global_position"):
			_player.call("set_global_position", xform.origin)

	emit_signal("player_spawned", _player)
	return _player

func despawn_player() -> void:
	if is_instance_valid(_player):
		_player.queue_free()
	_player = null
