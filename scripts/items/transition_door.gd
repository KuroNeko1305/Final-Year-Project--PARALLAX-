extends Area2D

@export var next_scene: String = ""
@export var required_players: int = 2

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var door_label: Label = $DoorLabel
@onready var blue_gem_sprite: Sprite2D = $BlueGem
@onready var red_gem_sprite: Sprite2D = $RedGem

var is_door_open: bool = false
var players_in_area: Array = []

func _ready():
	# Start with door closed
	_set_door_state(false)
	
	# Set default next scene if not assigned
	if not next_scene or next_scene == "":
		# Determine next scene based on current scene
		var current_scene = get_tree().current_scene.scene_file_path
		print("Current scene: ", current_scene)
		
		if "puzzle1_map" in current_scene:
			next_scene = "res://scenes/maps/puzze2_map.tscn"
			print("Set next scene to puzzle2_map")
		elif "puzze2_map" in current_scene:
			next_scene = "res://scenes/maps/chapter_2.tscn"
			print("Set next scene to chapter_2")
		else:
			# Default fallback
			next_scene = "res://scenes/maps/chapter_2.tscn"
			print("Set default next scene to chapter_2")
	
	# Connect to gem manager signals
	if has_node("/root/GemManager"):
		var gem_manager = get_node("/root/GemManager")
		gem_manager.door_should_open.connect(_open_door)
		gem_manager.gems_state_changed.connect(_on_gems_state_changed)
	
	# Connect area signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Initialize gem sprites opacity (both start uncollected)
	if red_gem_sprite:
		red_gem_sprite.modulate.a = 0.196  # 50/255
	if blue_gem_sprite:
		blue_gem_sprite.modulate.a = 0.196  # 50/255
	
	# Ensure door gem sprites are not collectible (just visual indicators)
	_make_door_gems_non_collectible()
	
	# Update door state based on current gem collection
	_update_door_state()

func _make_door_gems_non_collectible():
	# Door gem sprites are just Sprite2D nodes - they have no collision by default
	# This function serves as documentation that these gems are visual-only
	print("Door gem sprites are visual indicators only - not collectible")

func _set_door_state(open: bool):
	is_door_open = open
	
	if open:
		# Open door - enable transition
		collision_shape.disabled = false
		if animated_sprite:
			animated_sprite.play("open")
		if door_label:
			door_label.text = "Touch to Enter"
			door_label.modulate = Color.GREEN
	else:
		# Closed door - disable transition  
		collision_shape.disabled = true
		if animated_sprite:
			animated_sprite.pause()
			animated_sprite.frame = 0  # Keep door closed
		if door_label:
			door_label.text = "Collect Both Gems"
			door_label.modulate = Color.RED

func _open_door():
	print("Door opening - both gems collected!")
	_set_door_state(true)
	print("Door state after opening: ", is_door_open)

func _on_gems_state_changed(red_collected: bool, blue_collected: bool):
	var both_collected = red_collected and blue_collected
	print("Gems state changed - Red: %s, Blue: %s, Both: %s" % [red_collected, blue_collected, both_collected])
	_set_door_state(both_collected)
	print("Door state set to: ", is_door_open)
	
	# Update gem sprites opacity - each gem becomes 100% opaque when collected individually
	if red_gem_sprite:
		if red_collected:
			red_gem_sprite.modulate.a = 1.0  # 100% opaque when red gem collected
			print("Red gem sprite set to 100% opacity")
		else:
			red_gem_sprite.modulate.a = 0.196  # Dim when not collected
			print("Red gem sprite set to dim opacity")
	
	if blue_gem_sprite:
		if blue_collected:
			blue_gem_sprite.modulate.a = 1.0  # 100% opaque when blue gem collected
			print("Blue gem sprite set to 100% opacity")
		else:
			blue_gem_sprite.modulate.a = 0.196  # Dim when not collected
			print("Blue gem sprite set to dim opacity")
	
	# Update label based on what's still needed
	if not both_collected:
		var missing_gems = []
		if not red_collected:
			missing_gems.append("Red")
		if not blue_collected:
			missing_gems.append("Blue")
		
		if door_label:
			door_label.text = "Need: " + " & ".join(missing_gems) + " Gems"
	else:
		if door_label:
			door_label.text = "Touch to Enter"

func _update_door_state():
	# Check current gem state from GemManager
	if has_node("/root/GemManager"):
		var gem_manager = get_node("/root/GemManager")
		var red_collected = gem_manager.red_gem_collected
		var blue_collected = gem_manager.blue_gem_collected
		var both_collected = gem_manager.are_both_gems_collected()
		
		print("Door updating state - Red: %s, Blue: %s, Both: %s" % [red_collected, blue_collected, both_collected])
		
		# Update door open/close state
		_set_door_state(both_collected)
		
		# Update gem sprite opacities based on current collection state
		_on_gems_state_changed(red_collected, blue_collected)

func _on_body_entered(body: Node2D):
	if not is_door_open:
		# Play door knock sound when trying to enter a closed door
		SoundManager.play_sound("door_knock", -8.0)
		print("Player entered transition area but door is closed")
		return
	
	# Play door open sound when entering an open door
	SoundManager.play_sound("door_open", -8.0)
	
	# Check if multiplayer exists and if we're the server
	if not multiplayer or not multiplayer.is_server():
		print("Not server - ignoring transition area entry")
		return
	
	# Check if it's a player
	if not body.is_in_group("players"):
		print("Non-player entered transition area: ", body.name)
		return
	
	# Simplified player ID detection - just use the authority ID
	var player_id = body.get_multiplayer_authority()
	
	# If that fails, try to parse from the body name
	if player_id == 0:
		var body_name = str(body.name)
		if body_name.is_valid_int():
			player_id = body_name.to_int()
		else:
			# Last resort - just count unique players by body reference
			player_id = body.get_instance_id()
	
	print("Player %d (body: %s) entered transition area. Authority: %d" % [player_id, body.name, body.get_multiplayer_authority()])
	
	if player_id not in players_in_area:
		players_in_area.append(player_id)
		print("Player ", player_id, " entered transition area. Total: ", players_in_area.size())
		
		# Check if all required players are in the area
		if players_in_area.size() >= required_players:
			print("All players ready! Transitioning to next scene...")
			call_deferred("transition_scene")
	else:
		print("Player ", player_id, " already in transition area")

func _on_body_exited(body):
	# Check if multiplayer exists and if we're the server
	if not multiplayer or not multiplayer.is_server():
		return
	
	# Check if it's a player
	if not body.is_in_group("players"):
		return
	
	# Use same simplified method as entry
	var player_id = body.get_multiplayer_authority()
	
	if player_id == 0:
		var body_name = str(body.name)
		if body_name.is_valid_int():
			player_id = body_name.to_int()
		else:
			player_id = body.get_instance_id()
	
	if player_id in players_in_area:
		players_in_area.erase(player_id)
		print("Player ", player_id, " left transition area. Total: ", players_in_area.size())

func transition_scene():
	print("Transition scene called. Door open: ", is_door_open, " Next scene: ", next_scene)
	
	# Double-check door is actually open
	if not is_door_open:
		print("Cannot transition - door is not open!")
		return
	
	# Server tells all clients to change scene
	if next_scene and next_scene != "":
		print("Starting scene transition to: ", next_scene)
		change_scene_for_all.rpc(next_scene)
	else:
		print("Error: No next_scene assigned!")

@rpc("authority", "call_local", "reliable")
func change_scene_for_all(scene_path: String):
	print("Changing scene to: ", scene_path)
	
	# Clear the current scene first
	get_tree().change_scene_to_file(scene_path)
	
	# After scene loads, clients notify server they're ready
	if multiplayer and not multiplayer.is_server():
		# Wait for scene to fully load before notifying server
		await get_tree().process_frame
		notify_server_ready.rpc_id(1)

@rpc("any_peer", "reliable")
func notify_server_ready():
	if multiplayer and multiplayer.is_server():
		var sender_id = multiplayer.get_remote_sender_id()
		print("Client ", sender_id, " is ready in new scene")
	# Server will respawn this client through MultiplayerSpawner
