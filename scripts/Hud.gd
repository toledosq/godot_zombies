extends CanvasLayer
class_name PlayerHud

@onready var health_bar = $VitalsContainer/HealthBar

signal ready_

func _ready():
	print("HUD: Ready")
	emit_signal("ready_")

func _on_health_changed(_player_id: int, value: int, max_value: int):
	print("HUD: Player health changed")
	health_bar.max_value = max_value
	health_bar.value = value

func _on_player_died(_player_id):
	print("HUD: Player died!")
