extends Node2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var interact_area = $InteractArea
@onready var climb_area = $ClimbArea
@onready var climb_collision = $ClimbArea/ClimbCollision

var is_dropped: bool = false
var players_in_range: Array = []

func _ready():
	# Ensure climb collision is disabled at start
	climb_collision.disabled = true
	
	# Make sure climb area is in the climbable group
	if not climb_area.is_in_group("climbable"):
		climb_area.add_to_group("climbable")
		print("Added climb_area to 'climbable' group")
	
	# Set and play the default animation so ladder is visible
	animated_sprite.animation = "default"
	animated_sprite.play()
	
	# Connect interact area signals
	interact_area.body_entered.connect(_on_interact_area_body_entered)
	interact_area.body_exited.connect(_on_interact_area_body_exited)
	
	print("Ladder ready at position: ", global_position)
	print("Climb area in groups: ", climb_area.get_groups())

func _process(_delta):
	# Only check for input if ladder hasn't dropped yet
	if is_dropped:
		return
	
	# Check for interact input from any player in range
	if players_in_range.size() > 0:
		for player in players_in_range:
			if player and is_instance_valid(player):
				# Only check input for the local player (multiplayer authority)
				if not player.is_multiplayer_authority():
					continue
				
				# Check each player's interact action
				var player_id = player.player_id
				var interact_action = "interact_p" + str(player_id)
				
				if Input.is_action_just_pressed(interact_action):
					drop_ladder_rpc.rpc()  # Call RPC to sync across network
					return  # Exit immediately after dropping

func _on_interact_area_body_entered(body):
	# Check if it's a player
	if body.is_in_group("players") or body is CharacterBody2D:
		if not players_in_range.has(body):
			players_in_range.append(body)
			print("Player %s entered ladder interact range" % body.name)

func _on_interact_area_body_exited(body):
	# Remove player from range
	if players_in_range.has(body):
		players_in_range.erase(body)
		print("Player %s exited ladder interact range" % body.name)

@rpc("any_peer", "call_local", "reliable")
func drop_ladder_rpc():
	drop_ladder()

func drop_ladder():
	# Double check - only drop once
	if is_dropped:
		print("Ladder already dropped, ignoring")
		return
	
	is_dropped = true
	print("Ladder dropping!")
	
	# Play ladder interact sound
	SoundManager.play_sound("ladder_interact", 5.0, randf_range(0.95, 1.05))
	
	# Immediately disable interact area to prevent multiple triggers
	interact_area.monitoring = false
	interact_area.monitorable = false
	
	# Play drop down animation
	animated_sprite.play("drop_down")
	
	# Wait for animation to finish, then enable climb collision
	await animated_sprite.animation_finished
	
	print("Ladder drop animation finished, enabling climb area")
	
	# Enable the climb area collision
	climb_collision.disabled = false
	
	# Clear players array
	players_in_range.clear()

# Optional: Function to reset ladder (if you need it)
func reset_ladder():
	is_dropped = false
	climb_collision.disabled = true
	interact_area.monitoring = true
	interact_area.monitorable = true
	players_in_range.clear()
	
	# Play default animation
	animated_sprite.animation = "default"
	animated_sprite.play()
