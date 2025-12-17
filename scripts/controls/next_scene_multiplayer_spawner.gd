extends MultiplayerSpawner

@export var network_player: PackedScene

func _ready():
	# Set up spawn points for the new map
	GlobalIntroduction.spawn_points_0  = $"../SpawnPoints/0".global_position
	GlobalIntroduction.spawn_points_1 = $"../SpawnPoints/1".global_position
	print("Spawn point 0 set to: %s" % GlobalIntroduction.spawn_points_0)
	print("Spawn point 1 set to: %s" % GlobalIntroduction.spawn_points_1)
	
	# Load player scenes if not already loaded from new location
	if GlobalIntroduction.player_0_scene == null:
		GlobalIntroduction.player_0_scene = load("res://scenes/players/player_0.tscn")
	if GlobalIntroduction.player_1_scene == null:
		GlobalIntroduction.player_1_scene = load("res://scenes/players/player_1.tscn")
	
	spawn_function = spawn_player
	
	if multiplayer.is_server():
		# Spawn all connected players immediately
		call_deferred("spawn_all_connected_players")

func spawn_all_connected_players():
	# Get all currently connected peers
	var peers = multiplayer.get_peers()
	
	print("Spawning server player (ID 1)")
	spawn(1)
	
	# Spawn each connected client
	for peer_id in peers:
		print("Spawning client player (ID ", peer_id, ")")
		spawn(peer_id)

func spawn_player(id):
	var player
	
	if id == 1:
		if GlobalIntroduction.player_0_scene:
			player = GlobalIntroduction.player_0_scene.instantiate()
			print("Spawning Player 0 in new scene (will position in _ready)")
		else:
			print("Error: player_0_scene is null!")
			return null
	else:
		if GlobalIntroduction.player_1_scene:
			player = GlobalIntroduction.player_1_scene.instantiate()
			print("Spawning Player 1 in new scene (will position in _ready)")
		else:
			print("Error: player_1_scene is null!")
			return null
	
	player.name = str(id)
	player.set_multiplayer_authority(id)
	
	print("Player ", id, " spawned in new scene")
	
	return player
