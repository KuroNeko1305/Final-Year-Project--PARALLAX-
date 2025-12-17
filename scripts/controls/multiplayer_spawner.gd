extends MultiplayerSpawner

func _ready():
	# Verify spawn points exist before setting them
	var spawn_point_0 = get_node_or_null("../SpawnPoints/0")
	var spawn_point_1 = get_node_or_null("../SpawnPoints/1")
	
	if spawn_point_0:
		GlobalIntroduction.spawn_points_0 = spawn_point_0.global_position
		print("Spawn point 0 set to: %s" % GlobalIntroduction.spawn_points_0)
	else:
		print("ERROR: Spawn point 0 not found!")
	
	if spawn_point_1:
		GlobalIntroduction.spawn_points_1 = spawn_point_1.global_position
		print("Spawn point 1 set to: %s" % GlobalIntroduction.spawn_points_1)
	else:
		print("ERROR: Spawn point 1 not found!")
	
	# Load player scenes from new location
	GlobalIntroduction.player_0_scene = load("res://scenes/players/player_0.tscn")
	GlobalIntroduction.player_1_scene = load("res://scenes/players/player_1.tscn")

	spawn_function = spawn_player
	
	# Connect to the peer_connected signal only on the server
	if multiplayer.is_server():
		call_deferred("spawn_initial_player", multiplayer.get_unique_id())
		multiplayer.peer_connected.connect(spawn_player_client)


func spawn_initial_player(id):
	spawn(id)


func spawn_player(id):
	var player

	if id == 1:
		player = GlobalIntroduction.player_0_scene.instantiate()
		print("Spawning Player 0 (will position in _ready)")
	else:
		# Use player_1_scene for client
		player = GlobalIntroduction.player_1_scene.instantiate()
		print("Spawning Player 1 (will position in _ready)")

	player.name = str(id)
	player.set_multiplayer_authority(id)

	print("Player ", id, " is connected")

	return player

func spawn_player_client(id):
	# Use the MultiplayerSpawner's spawn() method instead of manually adding
	spawn(id)
