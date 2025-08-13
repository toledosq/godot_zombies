class_name SaveManager extends Node

# Preload resources


@onready var game_state_manager: GameStateManager = %GameStateManager  # Transitions between game states
@onready var global_input_manager: GlobalInputManager = %GlobalInputManager  # Handles non-gameplay inputs (ie menu hotkeys etc))
@onready var global_audio_manager: GlobalAudioManager = %GlobalAudioManager  # Manages global audio (Main menu music, etc.))
@onready var save_manager: SaveManager = %SaveManager  # Manages saving/loading game data
@onready var current_scene: Node = %CurrentScene  # Placeholder for current scene (Main Menu, Game, etc.)
