extends StaticBody2D

# Wood log that can be broken by rocks falling from above
# Players can stand on it, but it breaks when hit by a rock from sufficient height

@export var min_break_velocity: float = 5.0  # Minimum velocity needed to break the log (lowered from 10.0)
@export var break_animation_duration: float = 1.0  # Duration of break animation

var is_broken: bool = false
var collision_shape: CollisionShape2D
var sprite_container: Node2D
var animation_player: AnimationPlayer
var break_detection_area: Area2D

func _ready():
	# Set multiplayer authority to the server (host)
	if multiplayer.is_server():
		set_multiplayer_authority(1)  # Server authority
		print("Wood log: Server has authority")
	else:
		print("Wood log: Client - server has authority")
	
	# Get node references
	collision_shape = $CollisionShape2D
	sprite_container = $Node2D  # Updated to match the actual scene structure
	animation_player = $AnimationPlayer
	break_detection_area = $BreakDetectionArea
	
	print("Wood log: Initializing - min_break_velocity = ", min_break_velocity)
	print("Wood log: BreakDetectionArea collision_mask = ", break_detection_area.collision_mask)
	
	# Connect the area detection signal
	break_detection_area.body_entered.connect(_on_break_detection_area_body_entered)
	
	# Connect animation finished signal to handle collision disabling
	animation_player.animation_finished.connect(_on_break_animation_finished)

func _on_break_detection_area_body_entered(body):
	"""Called when something enters the detection area above the log"""
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	print("🪵 Wood log detection triggered!")
	print("  Body name: ", body.name)
	print("  Body type: ", body.get_class())
	print("  Body groups: ", body.get_groups())
	print("  Is broken: ", is_broken)
	
	if is_broken:
		print("  ❌ Already broken, ignoring")
		print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		return
	
	# Check if it's a rock with sufficient velocity
	if body.is_in_group("pushable"):
		print("  ✅ Body is in 'pushable' group")
		if body is CharacterBody2D:
			print("  ✅ Body is CharacterBody2D")
			
			# Check both current velocity and stored landing velocity
			var rock_velocity = body.velocity.y
			var stored_velocity = 0.0
			if "landing_velocity" in body:
				stored_velocity = body.landing_velocity
			
			var effective_velocity = max(rock_velocity, stored_velocity)
			
			print("  📊 Rock velocity.y = %.2f" % rock_velocity)
			print("  📊 Rock landing_velocity = %.2f" % stored_velocity)
			print("  📊 Effective velocity = %.2f (min required: %.2f)" % [effective_velocity, min_break_velocity])
			
			# Check if rock is falling fast enough to break the log
			# Note: velocity.y is positive when falling down in Godot
			if effective_velocity >= min_break_velocity:
				print("  ✅ VELOCITY SUFFICIENT - BREAKING LOG!")
				print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
				break_log()
			else:
				print("  ❌ Velocity insufficient (need at least %.2f)" % min_break_velocity)
				print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		else:
			print("  ❌ Body is not CharacterBody2D, it's: ", body.get_class())
			print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	else:
		print("  ❌ Body is not in 'pushable' group")
		print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

func break_log():
	"""Break the wood log and start the break animation"""
	if is_broken:
		return
	
	# Only the server should process the breaking logic
	if multiplayer.is_server():
		print("Wood log: Server calling break RPC to all clients")
		print("Wood log: Connected peers: ", multiplayer.get_peers())
		_break_log_rpc.rpc()
		print("Wood log: RPC call sent")
	else:
		print("Wood log: Client cannot break log directly")

@rpc("authority", "call_local", "reliable")
func _break_log_rpc():
	"""RPC function to break the wood log on all clients"""
	print("Wood log: _break_log_rpc called on peer ", multiplayer.get_unique_id())
	
	if is_broken:
		print("Wood log: Already broken, ignoring RPC")
		return
	
	is_broken = true
	
	# Play your custom break animation
	animation_player.play("break")
	
	# Play wood break explosion sound at the log's position
	SoundManager.play_sound("wood_break", -5.0, randf_range(0.95, 1.05))
	
	print("Wood log is breaking!")

func _on_break_animation_finished(animation_name: String):
	"""Called when the break animation finishes"""
	if animation_name == "break":
		# Only the server should handle collision disabling
		if multiplayer.is_server():
			_disable_collision_rpc.rpc()

@rpc("authority", "call_local", "reliable")
func _disable_collision_rpc():
	"""RPC function to disable collision on all clients"""
	print("Wood log: _disable_collision_rpc called on peer ", multiplayer.get_unique_id())
	
	# Disable collision so players can pass through
	collision_shape.set_deferred("disabled", true)
	
	print("Wood log is completely broken - collision disabled")

func reset_log():
	"""Reset the log to its original state (useful for respawning/restarting)"""
	# Only the server should handle resetting
	if multiplayer.is_server():
		_reset_log_rpc.rpc()

@rpc("authority", "call_local", "reliable")
func _reset_log_rpc():
	"""RPC function to reset the log on all clients"""
	is_broken = false
	collision_shape.disabled = false
	sprite_container.visible = true
	# Reset all child sprites
	for child in sprite_container.get_children():
		if child is Sprite2D:
			child.modulate = Color(1, 1, 1, 1)
			child.scale = Vector2(1, 1)
	animation_player.stop()

func can_stand_on() -> bool:
	"""Check if players can currently stand on this log"""
	return not is_broken

# Optional: Add a method to check if the log is intact for other game logic
func is_intact() -> bool:
	return not is_broken
