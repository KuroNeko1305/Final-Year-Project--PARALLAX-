extends CanvasLayer


var player_id: int = 0

# References to UI elements
@onready var back_button = $MarginContainer/VBoxContainer/BackBtn
@onready var tab_container = $MarginContainer/VBoxContainer/TabContainer

# Audio tab references
@onready var music_slider = $MarginContainer/VBoxContainer/TabContainer/Audio/MarginContainer/VBoxContainer/MusicSection/MusicSlider
@onready var music_value_label = $MarginContainer/VBoxContainer/TabContainer/Audio/MarginContainer/VBoxContainer/MusicSection/HBoxContainer/ValueLabel
@onready var voice_slider = $MarginContainer/VBoxContainer/TabContainer/Audio/MarginContainer/VBoxContainer/VoiceSection/VoiceSlider
@onready var voice_value_label = $MarginContainer/VBoxContainer/TabContainer/Audio/MarginContainer/VBoxContainer/VoiceSection/HBoxContainer/ValueLabel
@onready var sfx_slider = $MarginContainer/VBoxContainer/TabContainer/Audio/MarginContainer/VBoxContainer/SFXSection/SFXSlider
@onready var sfx_value_label = $MarginContainer/VBoxContainer/TabContainer/Audio/MarginContainer/VBoxContainer/SFXSection/HBoxContainer/ValueLabel

# Input tab references
@onready var left_button = $MarginContainer/VBoxContainer/TabContainer/Input/MarginContainer/VBoxContainer/LeftSection/RemapButton
@onready var right_button = $MarginContainer/VBoxContainer/TabContainer/Input/MarginContainer/VBoxContainer/RightSection/RemapButton
@onready var up_button = $MarginContainer/VBoxContainer/TabContainer/Input/MarginContainer/VBoxContainer/UpSection/RemapButton
@onready var down_button = $MarginContainer/VBoxContainer/TabContainer/Input/MarginContainer/VBoxContainer/DownSection/RemapButton
@onready var dash_button = $MarginContainer/VBoxContainer/TabContainer/Input/MarginContainer/VBoxContainer/DashSection/RemapButton
@onready var hold_button = $MarginContainer/VBoxContainer/TabContainer/Input/MarginContainer/VBoxContainer/HoldSection/RemapButton
@onready var jump_button = $MarginContainer/VBoxContainer/TabContainer/Input/MarginContainer/VBoxContainer/JumpSection/RemapButton

# Graphics tab references - FIXED PATHS
@onready var theme_option = $MarginContainer/VBoxContainer/TabContainer/Graphics/MarginContainer/VBoxContainer/ThemeSection/OptionButton
@onready var brightness_slider = $MarginContainer/VBoxContainer/TabContainer/Graphics/MarginContainer/VBoxContainer/BrightnessSection/BrightnessSlider
@onready var brightness_value = $MarginContainer/VBoxContainer/TabContainer/Graphics/MarginContainer/VBoxContainer/BrightnessSection/HBoxContainer/ValueLabel

var is_remapping = false
var action_to_remap = ""
var button_remapping = null

func _ready():
	# Connect signals with null checks
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	# Audio sliders
	if music_slider:
		music_slider.value_changed.connect(_on_music_changed)
	if voice_slider:
		voice_slider.value_changed.connect(_on_voice_changed)
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_changed)
	
	# Input buttons
	if left_button:
		left_button.pressed.connect(_on_remap_pressed.bind("left", left_button))
	if right_button:
		right_button.pressed.connect(_on_remap_pressed.bind("right", right_button))
	if up_button:
		up_button.pressed.connect(_on_remap_pressed.bind("up", up_button))
	if down_button:
		down_button.pressed.connect(_on_remap_pressed.bind("down", down_button))
	if dash_button:
		dash_button.pressed.connect(_on_remap_pressed.bind("dash", dash_button))
	if hold_button:
		hold_button.pressed.connect(_on_remap_pressed.bind("interact", hold_button))
	if jump_button:
		jump_button.pressed.connect(_on_remap_pressed.bind("jump", jump_button))
	
	# Graphics
	if theme_option:
		theme_option.item_selected.connect(_on_theme_changed)
	else:
		push_error("ThemeOption not found! Check path: Graphics/MarginContainer/VBoxContainer/ThemeSection/OptionButton")
		
	if brightness_slider:
		brightness_slider.value_changed.connect(_on_brightness_changed)
	
	# Load settings
	load_settings()

func _input(event):
	if is_remapping and event is InputEventKey and event.pressed:
		remap_action(action_to_remap, event)
		is_remapping = false
		if button_remapping:
			button_remapping.text = event.as_text()
		button_remapping = null
		save_settings()

func _on_back_pressed():
	# Play UI close sound
	SoundManager.play_sound("ui_close", -5.0)
	
	save_settings()
	hide()

# Audio functions
func _on_music_changed(value: float):
	if music_value_label:
		music_value_label.text = str(int(value)) + "%"
	
	var bus_index = AudioServer.get_bus_index("Music")
	if bus_index != -1:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value / 100.0))

func _on_voice_changed(value: float):
	if voice_value_label:
		voice_value_label.text = str(int(value)) + "%"
	
	var bus_index = AudioServer.get_bus_index("Voice")
	if bus_index != -1:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value / 100.0))

func _on_sfx_changed(value: float):
	if sfx_value_label:
		sfx_value_label.text = str(int(value)) + "%"
	
	var bus_index = AudioServer.get_bus_index("SFX")
	if bus_index != -1:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value / 100.0))

# Input remapping functions
func _on_remap_pressed(action: String, button: Button):
	is_remapping = true
	action_to_remap = action
	button_remapping = button
	button.text = "Press any key..."

func remap_action(action: String, event: InputEvent):
	# Add player suffix to action name
	var player_action = action + "_p" + str(player_id)
	
	if InputMap.has_action(player_action):
		InputMap.action_erase_events(player_action)
		InputMap.action_add_event(player_action, event)

# Graphics functions
func _on_theme_changed(index: int):
	match index:
		0: # System theme (you can implement your own logic)
			print("System theme selected")
		1: # Light theme
			if ResourceLoader.exists("res://themes/light_theme.tres"):
				get_viewport().get_window().theme = load("res://themes/light_theme.tres")
		2: # Dark theme
			if ResourceLoader.exists("res://themes/dark_theme.tres"):
				get_viewport().get_window().theme = load("res://themes/dark_theme.tres")

func _on_brightness_changed(value: float):
	if brightness_value:
		brightness_value.text = str(int(value)) + "%"
	
	# Apply brightness to WorldEnvironment
	var env = get_tree().get_first_node_in_group("world_environment")
	if env and env.environment:
		env.environment.adjustment_brightness = 0.5 + (value / 100.0)

# Save/Load functions
func save_settings():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	# Load existing config to preserve other player's settings
	if err != OK:
		config = ConfigFile.new()
	
	var section_prefix = "player" + str(player_id)
	
	# Audio - separate per player
	if music_slider:
		config.set_value(section_prefix + "_audio", "music", music_slider.value)
	if voice_slider:
		config.set_value(section_prefix + "_audio", "voice", voice_slider.value)
	if sfx_slider:
		config.set_value(section_prefix + "_audio", "sfx", sfx_slider.value)
	
	# Input - separate per player
	for action in ["left", "right", "up", "down", "dash", "interact", "climb", "jump"]:
		var player_action = action + "_p" + str(player_id)
		if InputMap.has_action(player_action):
			var events = InputMap.action_get_events(player_action)
			if events.size() > 0:
				var event = events[0]
				if event is InputEventKey:
					# Save keycode as int instead of text
					config.set_value(section_prefix + "_input", action, event.keycode)
	# Graphics - separate per player
	if theme_option:
		config.set_value(section_prefix + "_graphics", "theme", theme_option.selected)
	if brightness_slider:
		config.set_value(section_prefix + "_graphics", "brightness", brightness_slider.value)
	
	config.save("user://settings.cfg")

func load_settings():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	var section_prefix = "player" + str(player_id)
	
	if err != OK:
		# Set default values
		if music_slider:
			music_slider.value = 100
		if voice_slider:
			voice_slider.value = 100
		if sfx_slider:
			sfx_slider.value = 100
		if theme_option:
			theme_option.selected = 0
		if brightness_slider:
			brightness_slider.value = 100
		return
	
	# Audio - load from player-specific section
	if config.has_section_key(section_prefix + "_audio", "music") and music_slider:
		music_slider.value = config.get_value(section_prefix + "_audio", "music")
	else:
		music_slider.value = 100
		
	if config.has_section_key(section_prefix + "_audio", "voice") and voice_slider:
		voice_slider.value = config.get_value(section_prefix + "_audio", "voice")
	else:
		voice_slider.value = 100
		
	if config.has_section_key(section_prefix + "_audio", "sfx") and sfx_slider:
		sfx_slider.value = config.get_value(section_prefix + "_audio", "sfx")
	else:
		sfx_slider.value = 100
	
	# Input - load from player-specific section
	for action in ["left", "right", "up", "down", "dash", "interact", "climb", "jump"]:
		if config.has_section_key(section_prefix + "_input", action):
			var keycode = config.get_value(section_prefix + "_input", action)
			
			# Convert keycode to display text
			var key_text = OS.get_keycode_string(keycode)
			update_button_text(action, key_text)
	
	# Graphics - load from player-specific section
	if config.has_section_key(section_prefix + "_graphics", "theme") and theme_option:
		theme_option.selected = config.get_value(section_prefix + "_graphics", "theme")
		_on_theme_changed(theme_option.selected)
	else:
		theme_option.selected = 0
		
	if config.has_section_key(section_prefix + "_graphics", "brightness") and brightness_slider:
		brightness_slider.value = config.get_value(section_prefix + "_graphics", "brightness")
	else:
		brightness_slider.value = 100

func update_button_text(action: String, key_text: String):
	match action:
		"left":
			if left_button:
				left_button.text = key_text
		"right":
			if right_button:
				right_button.text = key_text
		"up":
			if up_button:
				up_button.text = key_text
		"down":
			if down_button:
				down_button.text = key_text
		"dash":
			if dash_button:
				dash_button.text = key_text
		"interact":
			if hold_button:
				hold_button.text = key_text
		"jump":
			if jump_button:
				jump_button.text = key_text

func show_settings(player: int = 0):
	# Play UI open sound
	SoundManager.play_sound("ui_open", -5.0)
	
	player_id = player  # Store which player opened settings
	show()
	load_settings()
