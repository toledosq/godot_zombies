class_name PauseMenu extends CanvasLayer

@onready var continue_button: Button = $CenterContainer/Panel/VBoxContainer/ContinueButton
@onready var save_button: Button = $CenterContainer/Panel/VBoxContainer/SaveButton
@onready var load_button: Button = $CenterContainer/Panel/VBoxContainer/LoadButton
@onready var settings_button: Button = $CenterContainer/Panel/VBoxContainer/SettingsButton
@onready var quit_button: Button = $CenterContainer/Panel/VBoxContainer/QuitButton

signal continue_game_requested
signal save_game_requested
signal load_game_requested
signal settings_menu_requested
signal quit_game_requested

func _ready() -> void:
	# Receive input even when tree is paused
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# Hide Menu
	self.visible = false
	
	# Connect Buttons
	continue_button.pressed.connect(_on_continue_pressed)
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_continue_pressed() -> void:
	continue_game_requested.emit()

func _on_quit_pressed() -> void:
	quit_game_requested.emit()

func _on_save_pressed() -> void:
	save_game_requested.emit()

func _on_load_pressed() -> void:
	load_game_requested.emit()

func _on_settings_pressed() -> void:
	settings_menu_requested.emit()

func show_menu() -> void:
	visible = true

func hide_menu() -> void:
	visible = false
