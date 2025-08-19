class_name PauseMenu extends CanvasLayer

@onready var continue_button: Button = $CenterContainer/Panel/VBoxContainer/ContinueButton
@onready var save_button: Button = $CenterContainer/Panel/VBoxContainer/SaveButton
@onready var load_button: Button = $CenterContainer/Panel/VBoxContainer/LoadButton
@onready var settings_button: Button = $CenterContainer/Panel/VBoxContainer/SettingsButton
@onready var quit_button: Button = $CenterContainer/Panel/VBoxContainer/QuitButton

signal pause_toggle_requested


func _ready() -> void:
	# Receive input even when tree is paused
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		pause_toggle_requested.emit()
		get_tree().set_input_as_handled()
