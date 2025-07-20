extends Node
class_name HealthComponent

@export var max_health: int = 100
var current_health: int

signal health_changed(current:int, maximum:int)
signal died

func _ready() -> void:
	reset()

func set_max_health(value: int) -> void:
	max_health = max(value, 1)
	current_health = clamp(current_health, 0, max_health)
	emit_signal("health_changed", current_health, max_health)
	
func take_damage(amount: int) -> void:
	if amount <= 0:
		return
	current_health = max(current_health - amount, 0)
	emit_signal("health_changed", current_health, max_health)
	if current_health == 0:
		emit_signal("died")

func heal(amount: int) -> void:
	if amount <= 0:
		return
	current_health = min(current_health + amount, max_health)
	emit_signal("health_changed", current_health, max_health)

func is_alive() -> bool:
	return current_health > 0

func reset() -> void:
	# Call this on spawn/respawn to refill HP
	current_health = max_health
	emit_signal("health_changed", current_health, max_health)
