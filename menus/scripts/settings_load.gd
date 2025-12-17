extends Node

func _ready():
	load_player_settings(0)
	load_player_settings(1)

func load_player_settings(player_id: int):
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err != OK:
		return
	
	var section_prefix = "player" + str(player_id)
	
	# Load input mappings with player suffix
	var actions = ["left", "right", "up", "down", "dash", "interact", "jump"]
	for action in actions:
		if config.has_section_key(section_prefix + "_input", action):
			var keycode = config.get_value(section_prefix + "_input", action)
			var player_action = action + "_p" + str(player_id)
			apply_key_remap(player_action, keycode)
	
	# Audio settings (these can be shared or separate - your choice)
	if config.has_section_key(section_prefix + "_audio", "music"):
		var music_vol = config.get_value(section_prefix + "_audio", "music")
		var bus_index = AudioServer.get_bus_index("Music")
		if bus_index != -1:
			AudioServer.set_bus_volume_db(bus_index, linear_to_db(music_vol / 100.0))

func apply_key_remap(action: String, keycode: int):
	if not InputMap.has_action(action):
		return
	
	var event = InputEventKey.new()
	event.keycode = keycode
	
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
