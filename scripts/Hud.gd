extends CanvasLayer

@onready var health_bar = %HealthBar

func _ready():
	UiEventBus.connect("health_changed", _on_health_changed)
	UiEventBus.connect("player_died", _on_player_died)
	UiEventBus.connect("player_spawned", _on_player_spawned)

func _on_health_changed(value: int, max_value: int):
	print("HUD: Player health changed")
	health_bar.max_value = max_value
	health_bar.value = value

func _on_player_died():
	print("HUD: Player died!")

func _on_player_spawned(player):
	print("HUD: Player spawned")
	var hc = player.get_node("Health")
	_on_health_changed(hc.current_health, hc.max_health)
