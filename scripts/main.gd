extends Node3D

@onready var camera_rig = %CameraRig

func _ready():
	# When scene loads, populate item DB singleton
	# TODO: This should be at an even higher level - done during initial game start
	print("Loading ItemDB")
	for proto in ItemDatabase.library.items:
		print(proto.id, ": ", proto.display_name)
	
	# Spawn player in world
	var player = $Player
	_on_player_spawned(player)

func _on_player_health_changed(current: int, maximum: int):
	print("Main: Player Health Changed")
	UiEventBus.emit_health_changed(current, maximum)

func _on_player_died():
	print("Main: Player Died")
	UiEventBus.emit_player_died()

func _on_player_spawned(player):
	print("Main: Player Spawned")
	player.connect("player_health_changed", _on_player_health_changed)
	player.connect("player_died", _on_player_died)
	UiEventBus.emit_player_spawned(player)
	print("Main: Requesting Player emit current health")
	player.emit_current_health()
