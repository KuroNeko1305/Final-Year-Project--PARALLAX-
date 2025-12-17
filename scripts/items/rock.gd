extends CharacterBody2D

@export var gravity = 980  # Increased from 900 for more responsive falling
@export var friction = 800
@export var push_speed = 100.0

var was_on_floor: bool = false  # Track if rock was on floor last frame
var push_sound_timer: float = 0.0  # Timer for push sound
const PUSH_SOUND_INTERVAL: float = 0.4  # Time between push sounds

# Store the landing velocity for wood log detection
var landing_velocity: float = 0.0
var velocity_reset_timer: float = 0.0
const VELOCITY_RESET_DELAY: float = 0.05  # Small delay before resetting velocity


#func _ready() -> void:
	#if multiplayer.is_server():
		#set_multiplayer_authority(1) # server (host) owns initially


func _physics_process(delta):
	# Update push sound timer
	if push_sound_timer > 0:
		push_sound_timer -= delta
	
	# Update velocity reset timer
	if velocity_reset_timer > 0:
		velocity_reset_timer -= delta
		if velocity_reset_timer <= 0:
			landing_velocity = 0.0  # Clear landing velocity after delay
			print("🪨 Cleared landing_velocity after timer")
	
	# Store current velocity BEFORE applying physics (for wood log detection)
	var current_falling_velocity = velocity.y
	
	# Always apply gravity when not on floor
	if not is_on_floor():
		velocity.y += gravity * delta
		# Debug: Show falling velocity
		if velocity.y > 50:
			print("🪨 Rock falling with velocity Y: %.1f" % velocity.y)
		# Store the falling velocity for potential landing
		if velocity.y > 5.0:  # Only store significant velocities
			landing_velocity = velocity.y
			velocity_reset_timer = VELOCITY_RESET_DELAY
	
	# Call move_and_slide first
	move_and_slide()
	
	# NOW check if we landed (after move_and_slide so is_on_floor() is updated)
	if is_on_floor():
		# Check if rock just landed (was in air, now on floor)
		if not was_on_floor and current_falling_velocity > 100:  # Only if falling with some speed
			SoundManager.play_sound("stone_land", -3.0)
			print("🪨 Rock landed (velocity was: %.1f, landing_velocity: %.1f)" % [current_falling_velocity, landing_velocity])
		
		# Reset vertical velocity when on floor
		velocity.y = 0
		
		# Apply friction to stop sliding when not pushed
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	
	# Store floor state for next frame
	was_on_floor = is_on_floor()

func push(direction: float) -> void:
	velocity.x = direction * push_speed
	
	# Play push sound with cooldown to avoid spam
	if push_sound_timer <= 0:
		SoundManager.play_sound("stone_push", 1.0)
		push_sound_timer = PUSH_SOUND_INTERVAL
