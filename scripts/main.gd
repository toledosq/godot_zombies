extends Node

@export var splash_scene: PackedScene
@export var min_splash_time_sec: float = 1.0

# these two are loaded by the GameStateManager (exported there),
# but keep refs here in case we need to preload at boot time too.
@export var main_menu_scene: PackedScene
@export var game_container_scene: PackedScene

@onready var _gsm := %GameStateManager        as GameStateManager
@onready var _save := %SaveManager            # not used here yet, but ready
@onready var _current_scene_root := %CurrentScene

var _splash_instance: Node

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

	# Show splash immediately.
	_show_splash()

	# Kick off startup tasks and then move to MAIN_MENU.
	# (Do your shader compilation/warmups in _do_startup_tasks.)
	await _do_startup_tasks()
	await get_tree().create_timer(max(0.0, min_splash_time_sec)).timeout
	_hide_splash()

	# Tell the state manager to move to Main Menu.
	_gsm.change_state(GameStateManager.GameState.MAIN_MENU)


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
	# Example placeholders; replace.
	# await RenderingServer.call_deferred("frame_post_draw")  # (if we need a frame)
	await get_tree().process_frame
	return


# When the GSM finishes loading the Main Menu, it emits this with the instance.
# We then connect to the menu's "play_requested" signal so Main can order the state change.
func _on_main_menu_ready(menu: Node) -> void:
	if menu.has_signal("play_requested"):
		# Avoid duplicate connections on hot-reload.
		if not menu.is_connected("play_requested", Callable(self, "_on_play_requested")):
			menu.connect("play_requested", Callable(self, "_on_play_requested"))


func _on_play_requested() -> void:
	_gsm.change_state(GameStateManager.GameState.GAME)
