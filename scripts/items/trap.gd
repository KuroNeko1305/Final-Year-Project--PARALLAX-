extends Area2D

# Trap Area2D that causes players to die when they enter it
# Connect the body_entered signal to _on_body_entered in the editor

func _ready() -> void:
	# Connect the body_entered signal if not already connected
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	# Add to a group for easy identification
	add_to_group("traps")
	
	print("Trap initialized at position: %s" % global_position)

func _on_body_entered(body: Node2D) -> void:
	print("Trap detected body: %s" % body.name)
	
	# Check if the body is a player (has _die method)
	if body.has_method("_die"):
		print("Player %s touched the trap! Calling _die()" % body.name)
		body._die()
	elif body.is_in_group("players"):
		print("Player %s touched the trap! (group method)" % body.name)
		if body.has_method("_die"):
			body._die()
		else:
			print("Warning: Player doesn't have _die method!")
