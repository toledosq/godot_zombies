class_name TestWorld
extends Node3D

@export var player_scene: PackedScene
@export var spawn_points: Array[NodePath] = []

var players = {}

var debug_line_3d = preload("res://scripts/tests/debug_line_3d.gd")
var dbg_vert: DebugLine3D
var dbg_fwd:  DebugLine3D

const RAY_LENGTH := 10.0   # adjust as you like

func _ready():
	# When scene loads, populate item DB singleton (still TODO: Move higher)
	print("Loading ItemDB")
	for proto in ItemDatabase.library.items:
		print(proto.id, ": ", proto.display_name)
	
	# Spawn player in world
	spawn_players(1)
	
	# Instance and configure the vertical line (red)
	dbg_vert = debug_line_3d.new()
	dbg_vert.color = Color.RED
	add_child(dbg_vert)

	# Instance and configure the forward line (green)
	dbg_fwd = debug_line_3d.new()
	dbg_fwd.color = Color.GREEN
	add_child(dbg_fwd)

func _process(_delta: float) -> void:
	var pos: Vector3 = players[0].global_transform.origin

	# 1) Vertical: from player → straight up
	dbg_vert.point_start = pos
	dbg_vert.point_end	 = pos + Vector3.UP * RAY_LENGTH

	# 2) Forward: 1 m above player, in the direction they face
	#	 In Godot the “forward” is −Z in world space:
	var base = pos
	var forward_dir = -players[0].global_transform.basis.z.normalized()
	dbg_fwd.point_start = base
	dbg_fwd.point_end	= base + forward_dir * RAY_LENGTH

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
