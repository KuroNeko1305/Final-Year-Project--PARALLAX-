#extends CanvasLayer
#
## UI References
#@onready var panel = $Panel
#@onready var toggle_voice_btn = $Panel/MarginContainer/VBoxContainer/ToggleVoiceButton
#@onready var close_btn = $Panel/MarginContainer/VBoxContainer/HBoxContainer/CloseButton
#
## Player 1 (You)
#@onready var player1_label = $Panel/MarginContainer/VBoxContainer/Player1Label
#@onready var player1_icon = $Panel/MarginContainer/VBoxContainer/Player1Controls/Player1Icon
#@onready var player1_status = $Panel/MarginContainer/VBoxContainer/Player1Controls/Player1Status
#
## Player 2 (Other player)
#@onready var player2_label = $Panel/MarginContainer/VBoxContainer/Player2Label
#@onready var player2_mute_btn = $Panel/MarginContainer/VBoxContainer/Player2Controls/Player2MuteButton
#@onready var player2_volume_slider = $Panel/MarginContainer/VBoxContainer/Player2VolumeSlider
#@onready var player2_volume_label = $Panel/MarginContainer/VBoxContainer/Player2Volume
#
#var my_id: int = 0
#var other_player_id: int = 0
#
#func _ready():
	## Hide panel by default
	#panel.visible = false
	#
	## Initialize volume slider to 100%
	#player2_volume_slider.min_value = 0
	#player2_volume_slider.max_value = 200
	#player2_volume_slider.value = 100
	#player2_volume_label.text = "Volume: 100%"
	#
	## Connect buttons
	#toggle_voice_btn.pressed.connect(_on_toggle_voice_pressed)
	#close_btn.pressed.connect(_on_close_pressed)
	#player2_mute_btn.pressed.connect(_on_mute_pressed)
	#player2_volume_slider.value_changed.connect(_on_volume_changed)
	#
	## Connect voice chat signals
	#VoiceChat.player_speaking_changed.connect(_on_player_speaking_changed)
	#VoiceChat.player_muted_changed.connect(_on_player_muted_changed)
	#
	## Connect multiplayer signals
	#multiplayer.peer_connected.connect(_on_peer_connected)
	#multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	#
	#print("✅ Voice Manager ready")
	#print("Press TAB to open Voice Manager")
	#
	## Wait then setup player IDs
	#await get_tree().create_timer(0.5).timeout
	#setup_player_ids()
#
#func setup_player_ids():
	#if not multiplayer.has_multiplayer_peer():
		#print("⚠️ No multiplayer peer yet")
		#return
	#
	#my_id = multiplayer.get_unique_id()
	#print("My ID: ", my_id)
	#
	## Update Player 1 label (You)
	#player1_label.text = "Player 1 (You - ID: %d)" % my_id
	#
	## Get other player ID
	#var peers = multiplayer.get_peers()
	#print("Connected peers: ", peers)
	#
	#if peers.size() > 0:
		#other_player_id = peers[0]
		#player2_label.text = "Player 2 (ID: %d)" % other_player_id
		#print("Other player ID: ", other_player_id)
		#
		## Initialize volume for this player
		#VoiceChat.set_player_volume(other_player_id, 1.0)
	#else:
		#player2_label.text = "Player 2 (Waiting...)"
		#print("Waiting for other player...")
#
#func _on_peer_connected(id: int):
	#print("🔗 Peer connected: ", id)
	#other_player_id = id
	#player2_label.text = "Player 2 (ID: %d)" % other_player_id
	#
	## Initialize volume for new player
	#VoiceChat.set_player_volume(other_player_id, player2_volume_slider.value / 100.0)
	#
	## Update UI to show unmuted state
	#update_all_ui()
#
#func _on_peer_disconnected(id: int):
	#print("❌ Peer disconnected: ", id)
	#if id == other_player_id:
		#other_player_id = 0
		#player2_label.text = "Player 2 (Disconnected)"
#
#func _input(event):
	## Press Tab to toggle panel
	#if event.is_action_pressed("ui_text_completion_accept"):
		#toggle_panel()
		#get_viewport().set_input_as_handled()
#
#func toggle_panel():
	#panel.visible = !panel.visible
	#if panel.visible:
		#print("📋 Voice Manager opened")
		#update_all_ui()
#
#func _on_close_pressed():
	#panel.visible = false
#
#func _on_toggle_voice_pressed():
	#VoiceChat.toggle_voice()
	#update_voice_button()
#
#func update_voice_button():
	#if VoiceChat.is_voice_enabled():
		#toggle_voice_btn.text = "🎤 Voice ON - Click to Disable"
		#toggle_voice_btn.add_theme_color_override("font_color", Color.GREEN)
	#else:
		#toggle_voice_btn.text = "🔇 Voice OFF - Click to Enable"
		#toggle_voice_btn.remove_theme_color_override("font_color")
#
#func _on_mute_pressed():
	#if other_player_id > 0:
		#VoiceChat.toggle_mute_player(other_player_id)
		#print("🔇 Toggled mute for player ", other_player_id)
#
#func _on_volume_changed(value: float):
	#player2_volume_label.text = "Volume: %d%%" % int(value)
	#
	#if other_player_id > 0:
		#var volume_multiplier = value / 100.0
		#VoiceChat.set_player_volume(other_player_id, volume_multiplier)
		#print("🔊 Set player ", other_player_id, " volume to ", volume_multiplier)
#
#func _on_player_speaking_changed(player_id: int, is_speaking: bool):
	#print("🎤 Speaking: Player ", player_id, " = ", is_speaking)
	#
	#if player_id == my_id:
		## Update Player 1 (You)
		#if is_speaking:
			#player1_icon.texture = load("res://introduction/assets/mic.png")
			#player1_icon.modulate = Color.GREEN
			#player1_status.text = "Speaking..."
		#else:
			#player1_icon.texture = load("res://introduction/assets/mic-off.png")
			#player1_icon.modulate = Color.WHITE
			#player1_status.text = "Not Speaking"
#
#func _on_player_muted_changed(player_id: int, is_muted: bool):
	#print("🔇 Muted state changed: Player ", player_id, " = ", is_muted)
	#
	#if player_id == other_player_id:
		#if is_muted:
			## When muted, show "unmute" icon (speaker with X)
			#player2_mute_btn.text = "🔇 Unmute"
			#player2_mute_btn.add_theme_color_override("font_color", Color.RED)
		#else:
			## When unmuted, show "mute" icon (normal speaker)
			#player2_mute_btn.text = "🔊 Mute"
			#player2_mute_btn.remove_theme_color_override("font_color")
#
#func update_all_ui():
	#update_voice_button()
	#
	## Update speaking states
	#if my_id > 0:
		#var my_speaking = VoiceChat.is_player_speaking(my_id)
		#_on_player_speaking_changed(my_id, my_speaking)
	#
	#if other_player_id > 0:
		#var other_speaking = VoiceChat.is_player_speaking(other_player_id)
		#_on_player_speaking_changed(other_player_id, other_speaking)
		#
		#var is_muted = VoiceChat.is_player_muted(other_player_id)
		#_on_player_muted_changed(other_player_id, is_muted)
		#
		## Update volume display
		#var current_volume = VoiceChat.get_player_volume(other_player_id)
		#player2_volume_slider.value = current_volume * 100.0
		#player2_volume_label.text = "Volume: %d%%" % int(current_volume * 100.0)
