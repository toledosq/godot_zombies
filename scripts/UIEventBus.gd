extends Node

signal health_changed(current: int, maximum: int)
signal player_died
signal player_spawned(player: Player)

func emit_health_changed(current: int, maximum: int):
	print("UI EventBus: Player Health Changed")
	emit_signal("health_changed", current, maximum)

func emit_player_died():
	print("UI EventBus: Player Died")
	emit_signal("player_died")

func emit_player_spawned(player: Player):
	print("UI EventBus: Player Spawned")
	emit_signal("player_spawned", player)
