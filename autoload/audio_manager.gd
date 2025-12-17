extends Node

# Audio players
var music_player_1: AudioStreamPlayer
var music_player_2: AudioStreamPlayer
var current_player: AudioStreamPlayer
var next_player: AudioStreamPlayer

# Transition settings
var transition_duration: float = 2.0
var is_transitioning: bool = false
var current_tween: Tween = null  # Track the current tween for cancellation

# Music database - map music by scene/map name
var music_tracks: Dictionary = {
	"introduction_map": "res://assets/musics/introduction_map.wav",
	"puzzle1": "res://assets/musics/puzzle1.mp3",
	"puzzle2": "res://assets/musics/puzzle2.mp3",
	"menu": "res://assets/musics/menu.wav",
}

var current_map: String = ""

func _ready() -> void:
	# Create two music players for crossfading
	music_player_1 = AudioStreamPlayer.new()
	music_player_2 = AudioStreamPlayer.new()
	
	add_child(music_player_1)
	add_child(music_player_2)
	
	# Set to music bus (create this in Audio Bus settings)
	music_player_1.bus = "Music"
	music_player_2.bus = "Music"
	
	# Initialize
	current_player = music_player_1
	next_player = music_player_2
	current_player.volume_db = 0
	next_player.volume_db = -80

func play_map_music(map_name: String) -> void:
	"""Play music for a specific map with transition"""
	if map_name == current_map and current_player.playing and not is_transitioning:
		return  # Already playing this map's music and not transitioning
	
	if not music_tracks.has(map_name):
		push_warning("No music found for map: " + map_name)
		return
	
	var music_path = music_tracks[map_name]
	var music = load(music_path)
	
	if music == null:
		push_error("Failed to load music: " + music_path)
		return
	
	# Cancel any ongoing transition
	if is_transitioning and current_tween:
		current_tween.kill()
		is_transitioning = false
	
	current_map = map_name
	
	# If no music is playing, start immediately
	if not current_player.playing:
		current_player.stream = music
		current_player.volume_db = 0
		current_player.play()
		print("🎵 Started playing: " + map_name)
		return
	
	# Otherwise, crossfade to new music
	print("🎵 Crossfading to: " + map_name)
	transition_to_music(music)

func transition_to_music(new_music: AudioStream) -> void:
	"""Crossfade between current and new music"""
	# Stop any existing transition
	if current_tween:
		current_tween.kill()
	
	is_transitioning = true
	
	# Set up next player
	next_player.stream = new_music
	next_player.volume_db = -80
	next_player.play()
	
	# Create tween for crossfade
	current_tween = create_tween()
	current_tween.set_parallel(true)
	
	# Fade out current music
	current_tween.tween_property(current_player, "volume_db", -80, transition_duration)
	
	# Fade in new music
	current_tween.tween_property(next_player, "volume_db", 0, transition_duration)
	
	# Swap players when done
	current_tween.chain().tween_callback(func():
		current_player.stop()
		current_player.volume_db = 0  # Reset volume for next use
		var temp = current_player
		current_player = next_player
		next_player = temp
		is_transitioning = false
		current_tween = null
		print("✓ Music transition completed")
	)

func stop_music(fade_out: bool = true) -> void:
	"""Stop the current music"""
	# Cancel any ongoing transition
	if current_tween:
		current_tween.kill()
		current_tween = null
	
	if fade_out:
		var tween = create_tween()
		tween.tween_property(current_player, "volume_db", -80, transition_duration)
		tween.tween_callback(func():
			current_player.stop()
			current_player.volume_db = 0
			current_map = ""
			print("🎵 Music stopped")
		)
	else:
		current_player.stop()
		current_player.volume_db = 0
		current_map = ""
		print("🎵 Music stopped (immediate)")

func set_music_volume(volume_percent: float) -> void:
	"""Set music volume (0.0 to 1.0)"""
	var db = linear_to_db(volume_percent)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db)

func set_transition_duration(duration: float) -> void:
	"""Change the crossfade duration"""
	transition_duration = duration

# For multiplayer sync if needed
func _sync_music_to_clients(map_name: String) -> void:
	"""Call this on server to sync music to all clients"""
	rpc("_client_play_music", map_name)

@rpc("authority", "call_local")
func _client_play_music(map_name: String) -> void:
	play_map_music(map_name)
