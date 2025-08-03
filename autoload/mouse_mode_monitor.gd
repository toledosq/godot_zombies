# mouse_mode_monitor.gd (Autoload)
extends Node

signal mouse_mode_changed(new_mode)

var _previous_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE

func _ready():
	_previous_mouse_mode = Input.mouse_mode

func _process(_delta):
	if Input.mouse_mode != _previous_mouse_mode:
		emit_signal("mouse_mode_changed", Input.mouse_mode)
		_previous_mouse_mode = Input.mouse_mode
