extends Node
class_name GameManager

@export var world_manager_path: NodePath = ^"WorldManager"
@export var initial_world: PackedScene		   # e.g. res://worlds/World_Overworld.tscn
@export var player_scene: PackedScene
@export var start_immediately := true
@export var spawn_tag := "default"			   # optional: named spawn variant

@onready var _wm := get_node(world_manager_path) as WorldManager
var _player: Node3D

func _ready() -> void:
	# (Main/GameStateManager) will instance Game.tscn under CurrentScene.
	# To allow Game.tscn to auto-start when it’s ready:
	if start_immediately and initial_world and player_scene:
		_start_session()

func _start_session() -> void:
	# 1) Load world
	await _wm.load_world(initial_world)
	# 2) Spawn player
	_player = await _wm.spawn_player(player_scene, spawn_tag)
	# Wire HUD, cameras, etc., now that the player exists.

func change_world(new_world: PackedScene, new_spawn_tag := "default") -> void:
	# Example API if you want to swap levels inside GAME state
	spawn_tag = new_spawn_tag
	await _wm.load_world(new_world)
	_player = await _wm.respawn_player(spawn_tag)  # keep same player instance, move it

func _on_player_health_changed(player_id_, current: int, maximum: int):
	print("Main: Player %d Health Changed " % player_id_, current, "/", maximum)


func _on_player_died(player_id_: int):
	print("Main: Player %d Died" % player_id_)
