extends Node

# Sound effect pool
var sfx_players: Array[AudioStreamPlayer] = []
var max_sfx_players: int = 16
var next_player_index: int = 0

# Sound effect database
var sounds: Dictionary = {
	"jump": "res://assets/sounds/Bounce Jump/Retro Jump 01.wav",
	"land": "res://assets/sounds/Bounce Jump/Retro Jump Simple A 01.wav",
	"ui_open": "res://assets/sounds/UI/UI Open.wav",
	"ui_close": "res://assets/sounds/UI/UI Close.wav",
	"dash": "res://assets/sounds/Swoosh/Retro Swooosh 07.wav",
	"explosion": "res://assets/sounds/Explosion/Retro Explosion Short 01.wav",
	"wood_break": "res://assets/sounds/Explosion/Retro Explosion Short 15.wav",
	"gem_pick": "res://assets/sounds/Coins/Retro PickUp Coin StereoUP 04.wav",
	"door_knock": "res://assets/sounds/Doors/door_knock.wav",
	"door_open": "res://assets/sounds/Doors/door_open.wav",
	"hurt": "res://assets/sounds/Coins/hurt.wav",
	"stone_land": "res://assets/sounds/FootStep/Retro FootStep Krushed Landing 01.wav",
	"water_land": "res://assets/sounds/Blops/Retro Blop StereoUP 04.wav",
	"stone_push": "res://assets/sounds/Stones/stone_push_short.wav",
	"ladder_open": "res://assets/sounds/Coins/wood_small_gather.wav",
	"ladder_interact": "res://assets/sounds/Coins/wood_small_gather.wav",
	"platform_drop": "res://assets/sounds/Coins/industrial_door_close.wav",
}

# Sound variations - for sounds with multiple versions
var sound_variations: Dictionary = {
	"footstep": [
		"res://assets/sounds/FootStep/Retro FootStep 03.wav",
		"res://assets/sounds/FootStep/Retro FootStep Grass 01.wav",
		"res://assets/sounds/FootStep/Retro FootStep Mud 01.wav",
	],
	"jump_variation": [
		"res://assets/sounds/Bounce Jump/Retro Jump 01.wav",
		"res://assets/sounds/Bounce Jump/Retro Jump Classic 08.wav",
		"res://assets/sounds/Bounce Jump/Retro Jump Simple B 05.wav",
	],
	"swim": [
		"res://assets/sounds/Blops/Retro Blop 18.wav",
		"res://assets/sounds/Blops/Retro Blop 22.wav",
		"res://assets/sounds/Blops/Retro Blop StereoUP 04.wav",
		"res://assets/sounds/Blops/Retro Blop StereoUP 09.wav"
	],
	"ui_click": [
		"res://assets/sounds/Pops/pop_1.wav",
		"res://assets/sounds/Pops/pop_2.wav",
		"res://assets/sounds/Pops/pop_3.wav",
	],
}

func _ready() -> void:
	# Create a pool of AudioStreamPlayer nodes
	for i in range(max_sfx_players):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)

func play_sound(sound_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	"""Play a sound effect"""
	var sound_path: String = ""
	
	# Check if it's a variation sound
	if sound_variations.has(sound_name):
		var variations = sound_variations[sound_name]
		sound_path = variations[randi() % variations.size()]
	elif sounds.has(sound_name):
		sound_path = sounds[sound_name]
	else:
		push_warning("Sound not found: " + sound_name)
		return
	
	var sound = load(sound_path)
	
	if sound == null:
		push_error("Failed to load sound: " + sound_path)
		return
	
	# Get next available player
	var player = sfx_players[next_player_index]
	next_player_index = (next_player_index + 1) % max_sfx_players
	
	player.stream = sound
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()

func play_sound_2d(sound_name: String, position: Vector2, volume_db: float = 0.0) -> void:
	"""Play a 2D positional sound (requires AudioStreamPlayer2D)"""
	var sound_path: String = ""
	
	# Check if it's a variation sound
	if sound_variations.has(sound_name):
		var variations = sound_variations[sound_name]
		sound_path = variations[randi() % variations.size()]
	elif sounds.has(sound_name):
		sound_path = sounds[sound_name]
	else:
		return
	
	var sound = load(sound_path)
	if sound == null:
		return
	
	var player = AudioStreamPlayer2D.new()
	player.bus = "SFX"
	player.stream = sound
	player.volume_db = volume_db
	player.global_position = position
	
	get_tree().root.add_child(player)
	player.play()
	
	# Auto-delete when finished
	player.finished.connect(func(): player.queue_free())

func play_sound_3d(sound_name: String, position: Vector3, volume_db: float = 0.0) -> void:
	"""Play a 3D positional sound (requires AudioStreamPlayer3D)"""
	var sound_path: String = ""
	
	# Check if it's a variation sound
	if sound_variations.has(sound_name):
		var variations = sound_variations[sound_name]
		sound_path = variations[randi() % variations.size()]
	elif sounds.has(sound_name):
		sound_path = sounds[sound_name]
	else:
		return
	
	var sound = load(sound_path)
	if sound == null:
		return
	
	var player = AudioStreamPlayer3D.new()
	player.bus = "SFX"
	player.stream = sound
	player.volume_db = volume_db
	player.global_position = position
	
	get_tree().root.add_child(player)
	player.play()
	
	# Auto-delete when finished
	player.finished.connect(func(): player.queue_free())

func set_sfx_volume(volume_percent: float) -> void:
	"""Set SFX volume (0.0 to 1.0)"""
	var db = linear_to_db(volume_percent)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), db)
