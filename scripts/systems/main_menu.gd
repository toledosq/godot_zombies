extends Control

signal play_requested
signal exit_requested

@onready var _play_button := %PlayButton  # use a node with this name or change the path

func _ready() -> void:
	_play_button.pressed.connect(_on_play_pressed)

func _on_play_pressed() -> void:
	play_requested.emit()

func _on_exit_pressed() -> void:
	exit_requested.emit()
