extends CanvasLayer

@onready var message_list = $Panel/VBoxContainer/ScrollContainer/MessageList
@onready var message_input = $Panel/VBoxContainer/HBoxContainer/MessageInput
@onready var send_button = $Panel/VBoxContainer/HBoxContainer/SendButton
@onready var panel = $Panel

var chat_enabled = false
var hide_timer: Timer
var auto_hide_delay = 5.0  # Seconds before chat auto-hides

func _ready():
	send_button.pressed.connect(_on_send_button_pressed)
	message_input.text_submitted.connect(_on_message_submitted)
	message_input.focus_entered.connect(_on_input_focus_entered)
	message_input.focus_exited.connect(_on_input_focus_exited)
	
	# Create auto-hide timer
	hide_timer = Timer.new()
	hide_timer.one_shot = true
	hide_timer.timeout.connect(_on_hide_timer_timeout)
	add_child(hide_timer)
	
	# Start hidden
	panel.visible = false
	
	# Auto-detect game scenes
	check_scene_for_chat()
	
	# Connect to scene changes
	get_tree().node_added.connect(_on_scene_changed)

func _on_scene_changed(_node):
	check_scene_for_chat()

func check_scene_for_chat():
	var current_scene = get_tree().current_scene
	if current_scene == null:
		return
	
	var scene_name = current_scene.name
	
	# Define which scenes should have chat enabled
	var game_scenes = ["introduction", "chapter1"]
	var menu_scenes = ["MainMenu", "StartMenu", "OptionsMenu", "PauseMenu"]
	
	if scene_name in game_scenes:
		enable_chat()
	elif scene_name in menu_scenes:
		disable_chat()

func enable_chat():
	if chat_enabled:
		return
	
	chat_enabled = true
	add_message("System", "Press Enter to open chat", Color.GRAY)

func disable_chat():
	chat_enabled = false
	panel.visible = false
	hide_timer.stop()

func _input(event):
	if not chat_enabled:
		return
	
	# Press Enter to open chat (only when chat is closed)
	if event.is_action_pressed("chat_open") and not panel.visible:
		open_chat()
		get_viewport().set_input_as_handled()
	
	# Press V to toggle voice chat
	if event.is_action_pressed("voice_talk") and event.ctrl_pressed:
		#VoiceChat.toggle_voice() 
		get_viewport().set_input_as_handled()

func open_chat():
	panel.visible = true
	message_input.grab_focus()
	
	# Stop any existing timer
	hide_timer.stop()

func start_hide_timer():
	# Only start timer if input is not focused
	if not message_input.has_focus():
		hide_timer.start(auto_hide_delay)

func _on_hide_timer_timeout():
	# Only hide if input is not focused
	if not message_input.has_focus():
		panel.visible = false

func _on_input_focus_entered():
	# Stop hide timer while typing
	hide_timer.stop()

func _on_input_focus_exited():
	# Start hide timer when done typing
	start_hide_timer()

func _on_send_button_pressed():
	send_message()

func _on_message_submitted(_text: String):
	send_message()

func send_message():
	var message = message_input.text.strip_edges()
	
	if message.is_empty():
		# Close chat if empty message sent
		message_input.release_focus()
		start_hide_timer()
		return
	
	message_input.clear()
	
	# Send to other players via network
	rpc("receive_message", multiplayer.get_unique_id(), message)
	
	# Display locally (only once)
	receive_message(multiplayer.get_unique_id(), message)
	
	# Keep focus for more messages
	message_input.grab_focus()
	
	# Start hide timer after sending
	start_hide_timer()

@rpc("any_peer", "call_remote", "reliable")
func receive_message(sender_id: int, message: String):
	var sender_name = "Player " + str(sender_id)
	var color = Color.WHITE
	
	if sender_id == multiplayer.get_unique_id():
		sender_name = "You"
		color = Color.LIGHT_BLUE
	
	add_message(sender_name, message, color)
	
	# Show chat briefly when receiving messages
	if not panel.visible:
		panel.visible = true
		start_hide_timer()

func add_message(sender: String, message: String, color: Color = Color.WHITE):
	var formatted_message = "[color=#%s][b]%s:[/b] %s[/color]\n" % [
		color.to_html(false),
		sender,
		message
	]
	
	message_list.append_text(formatted_message)

# Public function to manually enable/disable from other scripts
func set_chat_enabled(enabled: bool):
	if enabled:
		enable_chat()
	else:
		disable_chat()

# Public function to change auto-hide delay
func set_auto_hide_delay(seconds: float):
	auto_hide_delay = seconds
