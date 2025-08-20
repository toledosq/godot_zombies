extends Node

@export var splash_scene: PackedScene
@export var min_splash_time_sec: float = 1.0
@export var fader_path: NodePath

# these two are loaded by the GameStateManager (exported there),
# but keep refs here in case we need to preload at boot time too.
@export var main_menu_scene: PackedScene = preload("res://scenes/ui/main_menu.tscn")
@export var game_container_scene: PackedScene = preload("res://scenes/systems/game.tscn")

@onready var _gsm: GameStateManager 					= %GameStateManager
@onready var _global_input: GlobalInputManager 			= %GlobalInputManager
@onready var _save : SaveManager						= %SaveManager # not used here yet, but ready
@onready var _current_scene_root: Node					= %CurrentScene # container for scenes

var _fader: Node = null
var _splash_instance: Node
var _is_quitting := false
var _game_manager: GameManager = null


func _ready() -> void:
	# Give the GSM a handle to the container where scenes should be placed.
	_gsm.current_scene_root = _current_scene_root

	# Pass scene refs if you want to configure them here rather than in the GSM inspector.
	if main_menu_scene:
		_gsm.main_menu_scene = main_menu_scene
	if game_container_scene:
		_gsm.game_scene = game_container_scene

	# Listen for GSM telling us when the menu is ready so we can hook Play → change state.
	_gsm.main_menu_ready.connect(_on_main_menu_ready)
	_gsm.game_ready.connect(_on_game_ready)

	# Connect to GameStateManager for mouse mode changes
	_gsm.mouse_mode_changed.connect(_on_mouse_mode_changed)
	
	# Connect GlobalInputManager signals
	_global_input.ui_cancel_requested.connect(_on_ui_cancel_requested)

	# Show splash immediately.
	_show_splash()

	# Kick off startup tasks and then move to MAIN_MENU.
	# (Do shader compilation/warmups in _do_startup_tasks.)
	await _do_startup_tasks()
	await get_tree().create_timer(max(0.0, min_splash_time_sec)).timeout
	_hide_splash()

	# Tell the state manager to move to Main Menu.
	_gsm.change_state(GameStateManager.GameState.MAIN_MENU)


func _on_mouse_mode_changed(new_mouse_mode: Input.MouseMode) -> void:
	# This is now handled by the GameStateManager, but we can add logging if needed
	print("Main: Mouse mode changed to: ", new_mouse_mode)


func _show_splash() -> void:
	if splash_scene and is_instance_valid(_current_scene_root):
		_splash_instance = splash_scene.instantiate()
		_current_scene_root.add_child(_splash_instance)
		_current_scene_root.move_child(_splash_instance, 0) # keep at bottom if needed


func _hide_splash() -> void:
	if _splash_instance:
		_splash_instance.queue_free()
		_splash_instance = null


# Do any one-time startup work here (shader warmup, caches, save migration, etc).
# Keep it async-friendly so the splash stays up while this runs.
func _do_startup_tasks() -> void:
	# When application loads, populate item DB singleton
	print("Loading ItemDB")
	for proto in ItemDatabase.library.items:
		print(proto.id, ": ", proto.display_name)
		
	await get_tree().process_frame
	return


# When the GSM finishes loading the Main Menu, it emits this with the instance.
# We then connect to the menu's "play_requested" signal so Main can order the state change.
func _on_main_menu_ready(menu: Node) -> void:
	if menu.has_signal("play_requested"):
		# Avoid duplicate connections on hot-reload.
		if not menu.is_connected("play_requested", _on_play_requested):
			menu.connect("play_requested", _on_play_requested)
	if menu.has_signal("exit_requested"):
		if not menu.is_connected("exit_requested", quit_to_desktop):
			menu.connect("exit_requested", quit_to_desktop)


func _on_game_ready(game_manager: Node) -> void:
	_game_manager = game_manager
	if _game_manager.has_signal("quit_to_main_menu_requested"):
		_game_manager.connect("quit_to_main_menu_requested", _on_quit_to_main_menu_requested)
	if _game_manager.has_signal("continue_requested"):
		_game_manager.connect("continue_requested", _on_continue_requested)


func _on_quit_to_main_menu_requested() -> void:
	# Ensure we leave in a clean state
	get_tree().paused = false
	_gsm.change_state(GameStateManager.GameState.MAIN_MENU)
	_game_manager = null


func _on_play_requested() -> void:
	_gsm.change_state(GameStateManager.GameState.GAME)


func _on_ui_cancel_requested() -> void:
	if _game_manager:
		match _gsm.get_state():
			GameStateManager.GameState.GAME:
				_game_manager.toggle_pause_menu()
				_gsm.change_state(GameStateManager.GameState.PAUSED)
			GameStateManager.GameState.PAUSED:
				_game_manager.toggle_pause_menu()
				_gsm.change_state(GameStateManager.GameState.GAME)
			_:
				pass
	else:
		print("Main: Cannot process ui_cancel input - Game is not active")


func _on_continue_requested() -> void:
	if _game_manager:
		match _gsm.get_state():
			GameStateManager.GameState.PAUSED:
				_game_manager.toggle_pause_menu()
				_gsm.change_state(GameStateManager.GameState.GAME)
			_:
				pass


func quit_to_desktop() -> void:
	if _is_quitting:
		return
	_is_quitting = true
	_disable_input()

	# Optional: fade to black if we have a fader with an async API
	await _fade_out()

	# Let subsystems flush state
	await _save_on_quit_safe()
	await _gsm.prepare_for_quit()   # unloads active child safely

	# Quiet audio (quick + safe)
	_mute_master_bus()

	get_tree().quit()  # final exit

func _disable_input() -> void:
	# Mild guard so menu/game don’t react during shutdown
	get_tree().paused = true

func _fade_out() -> void:
	if _fader and _fader.has_method("fade_out"):
		await _fader.call("fade_out")  # returns when done

func _save_on_quit_safe() -> void:
	if _save and _save.has_method("save_game"):
		# await async save
		await _save.call("save_game")

func _mute_master_bus() -> void:
	var master := AudioServer.get_bus_index("Master")
	if master >= 0:
		AudioServer.set_bus_mute(master, true)
