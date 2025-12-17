extends Node2D

# Music settings
@export_group("Music")
@export var map_music_name: String = "introduction_map"  # Name of music track to play

# Camera limit settings for this map
@export_group("Camera Limits")
@export var camera_limit_left: int = -300
@export var camera_limit_right: int = 3188
@export var camera_limit_top: int = -800
@export var camera_limit_bottom: int = 480

# Welcome dialog settings
@export_group("Welcome Dialog")
@export var show_welcome_dialog: bool = true
@export var story_pages: Array[String] = [
	"There were two best-friend cats — <Player_0_name>, a white cat full of energy and bravery, and <Player_1_name>, a orange cat who preferred peace and comfort over danger. Though opposites, the two had shared countless adventures since they were little.",
	"One day, while wandering through the forest, <Player_0_name> discovered a mysterious cave hidden among the trees. Excited, he dashed back home to tell <Player_1_name>, who was busy playing games.",
	"Come on, <Player_1_name>! You have to see this!",
	"<Player_1_name> frowned, ears twitching. \"A cave? That sounds dangerous…\"",
	"But after much pleading — and a few playful headbutts — he finally sighed. \"Alright, alright. Just… don't make me regret it.\""
]

# Reference to the MultiplayerSpawner
@onready var spawner = $MultiplayerSpawner  # Adjust path if needed

func _ready():
	# Play the map's music
	if map_music_name != "":
		AudioManager.play_map_music(map_music_name)
	
	# Connect the spawner signal
	if spawner:
		spawner.spawned.connect(_on_player_spawned)
		print("Spawner connected")
	else:
		print("ERROR: spawner is null in _ready!")
	
	# Apply limits to any existing players (important for host)
	call_deferred("_apply_limits_to_existing_players")
	
	# Show welcome dialog after a short delay (only if enabled)
	if show_welcome_dialog:
		call_deferred("_show_welcome_dialog")


func _apply_limits_to_existing_players() -> void:
	# Check the spawn container for already-spawned players
	if spawner:
		var spawn_container = get_node_or_null(spawner.spawn_path)
		if spawn_container:
			print("Checking spawn container for existing players...")
			for child in spawn_container.get_children():
				if child.is_in_group("players") or child.has_method("set_camera_limits"):
					_apply_camera_limits(child)
	
	# Also check the entire tree as fallback
	for node in get_tree().get_nodes_in_group("players"):
		_apply_camera_limits(node)


func _on_player_spawned(node: Node) -> void:
	print("Player spawned:", node.name)
	# Wait a frame to ensure the player is fully initialized
	await get_tree().process_frame
	_apply_camera_limits(node)


func _apply_camera_limits(player: Node) -> void:
	if not player or not is_instance_valid(player):
		return
	
	# Prevent duplicate application
	if player.has_meta("camera_limits_applied"):
		return
	
	if player.has_method("set_camera_limits"):
		player.set_camera_limits(
			camera_limit_left,
			camera_limit_right,
			camera_limit_top,
			camera_limit_bottom
		)
		player.set_meta("camera_limits_applied", true)
		print("✓ Camera limits applied to player: %s" % player.name)
	else:
		print("⚠ Player %s doesn't have set_camera_limits method" % player.name)


func _show_welcome_dialog() -> void:
	print("DEBUG: _show_welcome_dialog() called")
	
	# Get the story pages with player names replaced
	var processed_pages = _process_story_pages()
	
	print("DEBUG: Processed ", processed_pages.size(), " pages")
	print("DEBUG: First page: ", processed_pages[0] if processed_pages.size() > 0 else "No pages")
	
	# Show the dialog using the Dialog autoload with processed pages
	Dialog.show_dialog(processed_pages)


func _process_story_pages() -> Array[String]:
	var processed_pages: Array[String] = []
	
	# Debug: Print current player names
	print("DEBUG: Player 0 name: ", GlobalIntroduction.player_0_name)
	print("DEBUG: Player 1 name: ", GlobalIntroduction.player_1_name)
	print("DEBUG: Current multiplayer ID: ", multiplayer.get_unique_id())
	
	# Get player names from global_introduction, with fallbacks
	var player_0_display_name = GlobalIntroduction.player_0_name if GlobalIntroduction.player_0_name != "Unnamed" else "Player 1"
	var player_1_display_name = GlobalIntroduction.player_1_name if GlobalIntroduction.player_1_name != "Unnamed" else "Player 2"
	
	print("DEBUG: Using names - Player 0: ", player_0_display_name, ", Player 1: ", player_1_display_name)
	
	# Process each page to replace placeholders
	for page in story_pages:
		var processed_page = page
		processed_page = processed_page.replace("<Player_0_name>", player_0_display_name)
		processed_page = processed_page.replace("<Player_1_name>", player_1_display_name)
		processed_pages.append(processed_page)
	
	return processed_pages
