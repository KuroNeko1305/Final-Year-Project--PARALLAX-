extends Node

var player_0_scene = null
var player_1_scene = null
var player_0_name: String = "Unnamed"
var player_1_name: String = "Unnamed"
var spawn_points_0 = null
var spawn_points_1 = null

var map_0
var map_1

# Simple RPC to sync player names
@rpc("any_peer", "call_local", "reliable")
func sync_player_names(p0_name: String, p1_name: String):
	player_0_name = p0_name
	player_1_name = p1_name
	print("Names synced - Player 0: ", p0_name, ", Player 1: ", p1_name)

# Check if both player names are properly set
func are_names_synchronized() -> bool:
	return player_0_name != "Unnamed" and player_1_name != "Unnamed"

# Called when a player sets their name
func set_player_name(player_id: int, player_name_text: String):
	if player_id == 0:
		player_0_name = player_name_text
	elif player_id == 1:
		player_1_name = player_name_text
	
	print("Setting player ", player_id, " name to: ", player_name_text)
	
	# Broadcast both names to all clients
	rpc("sync_player_names", player_0_name, player_1_name)
