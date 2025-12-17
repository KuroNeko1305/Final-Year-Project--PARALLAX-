extends Node

var chat_history: Array = []  # [{sender: String, text: String}]

@rpc("any_peer")
func server_receive_message(sender: String, text: String) -> void:
	# Save to history
	chat_history.append({ "sender": sender, "text": text })
	
	# Broadcast to everyone
	rpc("rpc_add_message", sender, text)

@rpc("call_local")
func rpc_add_message(sender: String, text: String) -> void:
	for box in get_tree().get_nodes_in_group("chatboxes"):
		if box.has_method("rpc_add_message"):
			box.rpc_add_message(sender, text)

# When a new client joins, they request full chat history
@rpc("any_peer")
func request_chat_history(peer_id: int) -> void:
	if multiplayer.is_server():
		# Send entire chat history to the newly joined player
		for msg in chat_history:
			rpc_id(peer_id, "rpc_add_message", msg.sender, msg.text)
