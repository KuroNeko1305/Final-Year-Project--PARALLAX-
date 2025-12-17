extends StaticBody2D

@export var required_players: int = 2
@export var drop_delay: float = 0.5  # Delay before dropping (for dramatic effect)

var players_in_area: Array = []
var has_dropped: bool = false

@onready var area_2d: Area2D = $Area2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	# Connect to the Area2D signals
	area_2d.body_entered.connect(_on_body_entered)
	area_2d.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	# Check if multiplayer exists and if we're the server (for consistency)
	# In single-player mode, multiplayer might be null, so allow that case
	if multiplayer and not multiplayer.is_server():
		return
	
	# Check if it's a player by checking both group membership and network authority
	if body.is_in_group("players") and (body.is_multiplayer_authority() or body.has_method("set_multiplayer_authority")):
		var player_id = body.name.to_int()
		
		if player_id not in players_in_area:
			players_in_area.append(player_id)
			print("Player ", player_id, " entered drop platform area. Total: ", players_in_area.size())
			
			# Check if all required players are in the area and platform hasn't dropped yet
			if players_in_area.size() >= required_players and not has_dropped:
				print("Both players detected! Platform will drop in ", drop_delay, " seconds...")
				# Add a small delay for dramatic effect
				await get_tree().create_timer(drop_delay).timeout
				
				# Double-check that both players are still in the area
				if players_in_area.size() >= required_players and not has_dropped:
					_trigger_drop()

func _on_body_exited(body):
	# Check if multiplayer exists and if we're the server (for consistency)
	# In single-player mode, multiplayer might be null, so allow that case
	if multiplayer and not multiplayer.is_server():
		return
	
	if body.is_in_group("players") and (body.is_multiplayer_authority() or body.has_method("set_multiplayer_authority")):
		var player_id = body.name.to_int()
		
		if player_id in players_in_area:
			players_in_area.erase(player_id)
			print("Player ", player_id, " left drop platform area. Total: ", players_in_area.size())

func _trigger_drop():
	if has_dropped:
		return
	
	has_dropped = true
	print("Drop platform activated! Playing drop_down animation...")
	
	# Play platform drop sound
	SoundManager.play_sound("platform_drop", 1.0, randf_range(0.95, 1.05))
	
	# Use RPC to sync animation across all clients
	_play_drop_animation.rpc()

@rpc("authority", "call_local", "reliable")
func _play_drop_animation():
	print("Playing drop animation on client...")
	
	# Play the drop animation on this client
	if animation_player:
		animation_player.play("drop_down")
		
		# Optionally, disable the area detection after dropping
		area_2d.set_deferred("monitoring", false)
	else:
		print("Error: AnimationPlayer not found!")
