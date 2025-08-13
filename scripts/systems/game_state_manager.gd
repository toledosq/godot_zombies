class_name GameStateManager
extends Node

signal state_changed(new_state: GameState)
signal main_menu_ready(menu_scene: Node)
signal game_ready(game_scene: Node)

enum GameState { STARTUP, MAIN_MENU, GAME, PAUSED }

@export var main_menu_scene: PackedScene
@export var game_scene: PackedScene

# Set by Main at runtime.
var current_scene_root: Node

var _current_state: GameState = GameState.STARTUP
var _active_child: Node

func get_state() -> GameState:
	return _current_state


func change_state(new_state: GameState) -> bool:
	if new_state == _current_state:
		return true

	match new_state:
		GameState.MAIN_MENU:
			await _switch_to_main_menu()
		GameState.GAME:
			await _switch_to_game()
		GameState.PAUSED:
			# TODO: Should be implemented inside GAME container (pause tree, show UI).
			pass
		GameState.STARTUP:
			# Usually only at boot; nothing to do here.
			pass
		_:
			printerr("StateManager: Unknown state %s" % new_state)
			return false

	_current_state = new_state
	state_changed.emit(_current_state)
	return true


# --- Transitions ----------------------------------------------------------------

func _switch_to_main_menu() -> void:
	await _unload_active_child()

	if not main_menu_scene:
		printerr("StateManager: main_menu_scene not assigned.")
		return

	var menu := main_menu_scene.instantiate()
	_place_as_current(menu)
	main_menu_ready.emit(menu)


func _switch_to_game() -> void:
	# If transitioning from menu, clear it first.
	await _unload_active_child()

	if not game_scene:
		printerr("StateManager: game_scene not assigned.")
		return

	var game := game_scene.instantiate()
	_place_as_current(game)
	game_ready.emit(game)


# --- Helpers --------------------------------------------------------------------

func _place_as_current(node: Node) -> void:
	if not is_instance_valid(current_scene_root):
		printerr("StateManager: current_scene_root is not set/valid.")
		return
	current_scene_root.add_child(node)
	_active_child = node


func _unload_active_child() -> void:
	if _active_child and is_instance_valid(_active_child):
		_active_child.queue_free()
		await get_tree().process_frame  # ensure it’s gone before we add the next
	_active_child = null
