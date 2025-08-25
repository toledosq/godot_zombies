# res://DebugOverlay.gd
# Godot 4.x — GDScript
# Drop-in debug overlay. Press F3 to toggle visibility.

class_name DebugOverlay
extends CanvasLayer

@export var player_path: NodePath = NodePath("/root/Main/CurrentScene/GameManager/WorldManager/Overworld/actors/Player")
var player: Node3D
## Treat ground plane as XZ (common in 3D). If false, shows literal X/Y.
@export var use_xz_as_xy := true
## How many frame samples to smooth (higher = steadier numbers)
@export_range(1, 120, 1) var smoothing_samples := 30
## Movement thresholds (m/s) for state inference when player has no flags
@export var moving_threshold := 0.05
@export var sprinting_threshold := 5.0

# Static singleton so any script can call DebugOverlay.warn()/error()
static var _singleton: DebugOverlay

# UI refs
var _root_panel: PanelContainer
var _fps_label: Label
var _frame_label: Label
var _pos_label: Label
var _state_label: Label
var _speed_label: Label
var _log_text: RichTextLabel
var _logs := []        # ring buffer of strings
var _max_logs := 8

# Smoothing / measurements
var _deltas := PackedFloat32Array()
var _delta_sum := 0.0
var _last_pos: Vector3
var _have_last := false
var _last_speed := 0.0

var _resolve_timer: Timer
var _node_added_conn: int = 0


func _enter_tree() -> void:
	_singleton = self

func _ready() -> void:
	# Build UI
	layer = 99
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	# Begin auto-binding to the player when it exists.
	_start_player_resolution()

	visible = true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_debug_toggle"): # you can bind this; fallback below
		visible = not visible
	elif event is InputEventKey and event.pressed and not event.echo:
		# F3 fallback if no action is bound
		if (event.physical_keycode == KEY_F3):
			visible = not visible

func _process(delta: float) -> void:
	# Smooth frame timing
	_delta_sum += delta
	_deltas.append(delta)
	if _deltas.size() > int(smoothing_samples):
		_delta_sum -= _deltas[0]
		_deltas.remove_at(0)
	var sample_count: int = max(1, _deltas.size())
	var avg_delta:float = _delta_sum / sample_count
	var frame_ms: float = avg_delta * 1000.0
	var fps := Engine.get_frames_per_second()

	_frame_label.text = "Frame: %.2f ms" % frame_ms
	_fps_label.text = "FPS: %d" % int(round(fps))

	# Player info
	if is_instance_valid(player):
		var gp: Vector3 = player.global_position
		if use_xz_as_xy:
			# Show ground-plane coords as X/Y (X/Z in 3D)
			_pos_label.text = "Pos (X/Y):  %.2f, %.2f" % [gp.x, gp.z]
		else:
			_pos_label.text = "Pos (X/Y):  %.2f, %.2f" % [gp.x, gp.y]

		# Speed (m/s): prefer CharacterBody3D.velocity if available
		var speed := _infer_speed(player, avg_delta)
		_last_speed = speed
		_speed_label.text = "Speed:     %.2f m/s" % speed

		# State: prefer explicit flags on player, else infer
		var state := _infer_state(player, speed)
		_state_label.text = "State:     %s" % state
	else:
		_pos_label.text = "Pos (X/Y):  --, --"
		_speed_label.text = "Speed:     --"
		_state_label.text = "State:     (no player)"

func _infer_speed(p: Node, dt: float) -> float:
	# If it quacks like a CharacterBody3D…
	if p.has_method("get_velocity"):
		var v = p.call("get_velocity")
		if v is Vector3:
			return (v as Vector3).length()
	# Common property name on CharacterBody3D
	if p.has_variable("velocity"):
		var vv = p.get("velocity")
		if vv is Vector3:
			return (vv as Vector3).length()

	# Fallback: derive from position delta
	var gp: Vector3 = (p as Node3D).global_position
	if _have_last:
		var dist := gp.distance_to(_last_pos)
		_last_pos = gp
		return dist / max(0.000001, dt)
	else:
		_last_pos = gp
		_have_last = true
		return _last_speed # 0 on first frame

func _infer_state(p: Node, speed: float) -> String:
	# Respect explicit booleans if the player exposes them
	var crouch := false
	var sprint := false
	crouch = bool(p.get("is_crouching"))
	sprint = bool(p.get("is_sprinting"))

	if crouch: return "crouching"
	if sprint: return "sprinting"
	if speed >= 0.0: return "moving"
	return "idle"

func _build_ui() -> void:
	# Root panel
	_root_panel = PanelContainer.new()
	_root_panel.name = "DebugPanel"
	_root_panel.set_anchors_preset(Control.PRESET_TOP_LEFT, true)
	_root_panel.offset_top = 8
	_root_panel.offset_left = 8
	_root_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_root_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	add_child(_root_panel)

	# Semi-transparent background
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0,0,0,0.6) # semi-transparent black
	sb.set_border_width_all(1)
	sb.border_color = Color(1,1,1,0.25)
	sb.set_corner_radius_all(8)
	_root_panel.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(320, 0)
	vbox.add_theme_constant_override("separation", 4)
	_root_panel.add_child(vbox)

	# Header
	var title := Label.new()
	title.text = "Debug"
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)

	# Metrics grid
	var grid := GridContainer.new()
	grid.columns = 1
	vbox.add_child(grid)

	_frame_label = Label.new()
	_frame_label.text = "Frame: -- ms"
	grid.add_child(_frame_label)

	_fps_label = Label.new()
	_fps_label.text = "FPS: --"
	grid.add_child(_fps_label)

	_pos_label = Label.new()
	_pos_label.text = "Pos (X/Y): --, --"
	grid.add_child(_pos_label)

	_state_label = Label.new()
	_state_label.text = "State: --"
	grid.add_child(_state_label)

	_speed_label = Label.new()
	_speed_label.text = "Speed: --"
	grid.add_child(_speed_label)

	# Logs sub-box
	var logs_panel := PanelContainer.new()
	var logs_box := StyleBoxFlat.new()
	logs_box.bg_color = Color(0,0,0,0.4)
	logs_box.set_border_width_all(1)
	logs_box.border_color = Color(1,1,1,0.15)
	logs_box.set_corner_radius_all(6)
	logs_panel.add_theme_stylebox_override("panel", logs_box)
	vbox.add_child(logs_panel)

	var logs_v := VBoxContainer.new()
	logs_panel.add_child(logs_v)
	var logs_title := Label.new()
	logs_title.text = "Warnings / Errors"
	logs_v.add_child(logs_title)

	_log_text = RichTextLabel.new()
	_log_text.scroll_active = true
	_log_text.fit_content = true
	_log_text.custom_minimum_size = Vector2(300, 96)
	_log_text.bbcode_enabled = true
	logs_v.add_child(_log_text)

	# Hint for toggle key (small)
	var hint := Label.new()
	hint.text = "F3 to toggle"
	hint.modulate = Color(1,1,1,0.6)
	vbox.add_child(hint)

# ---- Public logging API ----------------------------------------------------

static func warn(msg: String) -> void:
	if _singleton:
		_singleton._add_log("WARN", msg)

static func error(msg: String) -> void:
	if _singleton:
		_singleton._add_log("ERROR", msg)

func _add_log(level: String, msg: String) -> void:
	var color := "ff6b6b" if level == "ERROR" else "ffd166"
	var line := "[%s] [color=#%s]%s[/color]" % [Time.get_time_string_from_system(), color, msg]
	_logs.append(line)
	if _logs.size() > _max_logs:
		_logs = _logs.slice(_logs.size() - _max_logs, _logs.size())
	_refresh_logs()

func _refresh_logs() -> void:
	_log_text.clear()
	for line in _logs:
		_log_text.append_bbcode(line + "\n")
	_log_text.scroll_to_line(_log_text.get_line_count() - 1)

func _start_player_resolution() -> void:
	# Listen for nodes being added (cheap way to notice when deep hierarchy spawns).
	if _node_added_conn == 0:
		if get_tree():
			_node_added_conn = get_tree().connect("node_added", Callable(self, "_on_tree_node_added"))
		
	# Quick try now, then periodically until found.
	_try_bind_player()
	
	# Timer to retry in case node_added fires before it's fully ready or the path changes.
	_resolve_timer = Timer.new()
	_resolve_timer.one_shot = false
	_resolve_timer.wait_time = 0.5
	add_child(_resolve_timer)
	_resolve_timer.timeout.connect(_try_bind_player)
	_resolve_timer.start()

func _stop_player_resolution() -> void:
	if _resolve_timer and is_instance_valid(_resolve_timer):
		_resolve_timer.stop()
		_resolve_timer.queue_free()
		_resolve_timer = null
	if _node_added_conn != 0:
		get_tree().disconnect("node_added", Callable(self, "_on_tree_node_added"))
		_node_added_conn = 0

func _on_tree_node_added(_n: Node) -> void:
	# Try to bind whenever something new enters the tree.
	if player == null:
		_try_bind_player()

func _try_bind_player() -> void:
	if not get_tree():
		return
	if player and is_instance_valid(player):
		return
	# 1) Try the configured path.
	var n := get_node_or_null(player_path)
	# 2) Fallback: search by name anywhere in the tree (non-recursive flag false -> allow recursion).
	if n == null:
		n = get_tree().root.find_child("Player", true, false)
	# If found and it’s a Node3D, bind and watch for exit.
	if n is Node3D:
		player = n
		# Rebind when player gets reloaded or freed (level changes etc.)
		player.tree_exited.connect(_on_player_exited_tree)
		_stop_player_resolution() # we’re done; no need to keep polling.

func _on_player_exited_tree() -> void:
	# Player went away (scene swap, reload, etc.) — resume looking.
	player = null
	_start_player_resolution()
