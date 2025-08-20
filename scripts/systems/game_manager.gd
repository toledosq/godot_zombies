class_name GameManager extends Node

signal quit_to_main_menu_requested
signal continue_requested

@export var world_manager_path: NodePath = ^"WorldManager"
@export var initial_world: PackedScene		   # e.g. res://worlds/World_Overworld.tscn
@export var player_scene: PackedScene
@export var start_immediately := true
@export var spawn_tag := "default"			   # optional: named spawn variant
@export var _gsm: GameStateManager

@onready var pause_overlay: PauseMenu 	= %PauseOverlay
@onready var _wm: WorldManager 			= get_node(world_manager_path)
var _player: Node3D


func _ready() -> void:
	# Connect Pause Menu Signals
	pause_overlay.continue_game_requested.connect(_on_continue_requested)
	pause_overlay.quit_game_requested.connect(_on_quit_to_main_menu_requested)
	
	# (Main/GameStateManager) will instance Game.tscn under CurrentScene.
	# To allow Game.tscn to auto-start when it’s ready:
	if start_immediately and initial_world and player_scene:
		_start_session()


func _start_session() -> void:
	# 1) Load world
	await _wm.load_world(initial_world)
	# 2) Spawn player
	_player = _wm.spawn_player(player_scene, spawn_tag)
	# 3) Hook up Mouse Mode Changed signal - enables player_hud to change cursor texture to crosshair when needed
	_gsm.mouse_mode_changed.connect(_player.player_hud._on_mouse_mode_changed)

	# Wire HUD, cameras, etc., now that the player exists.

	print("Main: Requesting Player emit current health")
	_player.emit_current_health()

	# Connect to player's inventory UI for mouse mode management
	if _player.has_node("InventoryUI"):
		var inventory_ui = _player.get_node("InventoryUI")
		inventory_ui.visibility_changed.connect(_on_inventory_ui_visibility_changed)


func change_world(new_world: PackedScene, new_spawn_tag := "default") -> void:
	# Example API if you want to swap levels inside GAME state
	spawn_tag = new_spawn_tag
	await _wm.load_world(new_world)
	_player = _wm.respawn_player(spawn_tag)  # keep same player instance, move it


func _on_inventory_ui_visibility_changed() -> void:
	# Only manage mouse mode when in GAME state
	if _gsm.get_state() == GameStateManager.GameState.GAME:
		if _player and _player.has_node("InventoryUI"):
			var inventory_ui = _player.get_node("InventoryUI")
			if inventory_ui.visible:
				_gsm.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				_gsm.set_mouse_mode(Input.MOUSE_MODE_CONFINED)


func _on_player_health_changed(player_id_, current: int, maximum: int):
	print("GameManager: Player %d Health Changed " % player_id_, current, "/", maximum)


func _on_player_died(player_id_: int):
	print("GameManager: Player %d Died" % player_id_)


func _on_continue_requested() -> void:
	continue_requested.emit()


func _on_quit_to_main_menu_requested() -> void:
	quit_to_main_menu_requested.emit()


func toggle_pause_menu() -> void:
	if get_tree().paused:
		_resume_game()
	else:
		_pause_game()


func _pause_game() -> void:
	get_tree().paused = true
	if pause_overlay:
		pause_overlay.show_menu()


func _resume_game() -> void:
	if pause_overlay:
		pause_overlay.hide_menu()
	get_tree().paused = false


func _on_continue() -> void:
	_resume_game()


func _on_quit_to_menu() -> void:
	# Hide UI and let Main handle the state transition
	if pause_overlay:
		pause_overlay.hide_menu()
	get_tree().paused = false
	emit_signal("quit_to_main_menu_requested")
