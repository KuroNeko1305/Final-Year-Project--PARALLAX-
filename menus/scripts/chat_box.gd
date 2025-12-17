extends CanvasLayer

@onready var chat_history: VBoxContainer = %ChatHistory
@onready var chat_input: LineEdit = %ChatInput

@export var player_name: String = ""
@export var font_path: String = "res://menus/Fonts/PixelOperator8.ttf"

var font: Font
var is_chatting := false
var messages: Array[Label] = []

func _ready() -> void:
	add_to_group("chatboxes")
	font = load(font_path)
	chat_input.visible = false
	chat_input.connect("text_submitted", _on_text_submitted)
	set_process_input(true)

	var peer_id = multiplayer.get_unique_id()
	if peer_id == 1:
		player_name = GlobalIntroduction.player_0_name
	else:
		player_name = GlobalIntroduction.player_1_name
	
	# Request chat history from server after joining
	#if not multiplayer.is_server():
		#ChatManager.rpc_id(1, "request_chat_history", peer_id)


func _input(event):
	# Only open chat if not currently chatting
	if !is_chatting and event.is_action_pressed("chat"):
		if event is InputEventKey and event.echo:
			return
		_toggle_chat()
		get_viewport().set_input_as_handled()

	# Handle chat input (while chatting)
	elif is_chatting:
		# Close chat with Esc
		if event.is_action_pressed("esc"):
			_toggle_chat()
			get_viewport().set_input_as_handled()


func _toggle_chat():
	is_chatting = !is_chatting
	chat_input.visible = is_chatting

	if is_chatting:
		chat_input.grab_focus()
	else:
		chat_input.release_focus()


# When player submits text (on the client)
func _on_text_submitted(text: String) -> void:
	text = text.strip_edges()
	if text == "":
		_toggle_chat()
		return

	# Send message to server or handle locally if we are the server
	if multiplayer.is_server():
		ChatManager.server_receive_message(player_name, text)
	else:
		ChatManager.rpc_id(1, "server_receive_message", player_name, text)

	chat_input.text = ""
	_toggle_chat()

# ---------- MESSAGE HANDLING ----------

# Local helper: adds message to UI only (no network)
func _add_message_local(sender: String, text: String) -> void:
	var label := Label.new()
	label.text = "%s: %s" % [sender, text]
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", chat_input.get_theme_font_size("font_size"))
	label.add_theme_color_override("font_color", Color.WHITE)
	chat_history.add_child(label)
	messages.append(label)


# Called by server to broadcast new messages to all clients
@rpc("any_peer", "call_local")
func rpc_add_message(sender: String, text: String) -> void:
	_add_message_local(sender, text)


# Called by server only for a new peer to receive the full history
@rpc("any_peer", "call_local")
func rpc_load_history(history: Array) -> void:
	for entry in history:
		if typeof(entry) == TYPE_DICTIONARY and entry.has("sender") and entry.has("text"):
			_add_message_local(entry["sender"], entry["text"])
