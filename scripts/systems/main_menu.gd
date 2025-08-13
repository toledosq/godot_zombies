extends Control

signal play_requested
signal exit_requested

@onready var _play_button: Button = %PlayButton
@onready var _exit_button: Button = %ExitButton


func _ready() -> void:
	_play_button.pressed.connect(_on_play_pressed)
	_exit_button.pressed.connect(_on_exit_pressed)

func _on_play_pressed() -> void:
	play_requested.emit()

func _on_exit_pressed() -> void:
	exit_requested.emit()
