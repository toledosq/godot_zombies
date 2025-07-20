extends Node3D
class_name Main

@export var player_scene: PackedScene
@export var spawn_points: Array[NodePath] = []

var players = {}

func _ready():
	# When scene loads, populate item DB singleton (still TODO: Move higher)
	print("Loading ItemDB")
	for proto in ItemDatabase.library.items:
		print(proto.id, ": ", proto.display_name)
	
	# Spawn player in world
	spawn_players(1)

func spawn_players(player_count: int):
	for i in player_count:
		# Instantiate a player scene
		var player = player_scene.instantiate()
		if player == null:
			push_error("Failed to instantiate player scene!")
			return
		
		# Assign player ID
		player.player_name = "Player%d" % i
		player.player_id = i
		
		# Spawn the player
		var spawn_transform = get_node(spawn_points[i]).global_transform
		player.global_transform = spawn_transform
		add_child(player)
		
		# Wire player signals
		_on_player_spawned(player)
		
		# Track player
		players[i] = player

func _on_player_spawned(player):
	# Connect the player signals
	player.connect("player_health_changed", _on_player_health_changed)
	player.connect("player_died", _on_player_died)
	
	# Announce spawn
	print("Main: Player %d Spawned " % player.player_id, player.player_name)
	
	# Request player emit initial health state
	print("Main: Requesting Player emit current health")
	player.emit_current_health()

func _on_player_health_changed(player_id_, current: int, maximum: int):
	print("Main: Player %d Health Changed " % player_id_, current, "/", maximum)

func _on_player_died(player_id_: int):
	print("Main: Player %d Died" % player_id_)
