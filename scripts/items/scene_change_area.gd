extends Area2D

@export var next_scene: String = ""
@export var required_players: int = 2

var players_in_area: Array = []

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	# Check if multiplayer exists and if we're the server
	if not multiplayer or not multiplayer.is_server():
		return
	
	# Check if it's a player by checking if it has a network authority
	if body.is_multiplayer_authority() or body.has_method("set_multiplayer_authority"):
		var player_id = body.name.to_int()
		
		if player_id not in players_in_area:
			players_in_area.append(player_id)
			print("Player ", player_id, " entered transition area. Total: ", players_in_area.size())
			
			# Check if all required players are in the area
			if players_in_area.size() >= required_players:
				print("All players ready! Transitioning to next scene...")
				call_deferred("transition_scene")

func _on_body_exited(body):
	# Check if multiplayer exists and if we're the server
	if not multiplayer or not multiplayer.is_server():
		return
	
	if body.is_multiplayer_authority() or body.has_method("set_multiplayer_authority"):
		var player_id = body.name.to_int()
		
		if player_id in players_in_area:
			players_in_area.erase(player_id)
			print("Player ", player_id, " left transition area. Total: ", players_in_area.size())

func transition_scene():
	# Server tells all clients to change scene
	if next_scene and next_scene != "":
		change_scene_for_all.rpc(next_scene)
	else:
		print("Error: No next_scene assigned!")

@rpc("authority", "call_local", "reliable")
func change_scene_for_all(scene_path: String):
	print("Changing scene to: ", scene_path)
	
	# Clear the current scene first
	get_tree().change_scene_to_file(scene_path)
	
	# After scene loads, clients notify server they're ready
	if multiplayer and not multiplayer.is_server():
		# Wait for scene to fully load before notifying server
		await get_tree().process_frame
		notify_server_ready.rpc_id(1)

@rpc("any_peer", "reliable")
func notify_server_ready():
	if multiplayer and multiplayer.is_server():
		var sender_id = multiplayer.get_remote_sender_id()
		print("Client ", sender_id, " is ready in new scene")
	# Server will respawn this client through MultiplayerSpawner
