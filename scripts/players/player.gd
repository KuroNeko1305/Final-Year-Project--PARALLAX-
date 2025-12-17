extends CharacterBody2D
class_name PlayerBase

@export var player_id: int = 0

# Movement Constants
const MOVE_SPEED = 150.0
const FALL_SPEED = 200.0
const JUMP_VELOCITY = -450.0
const COOP_JUMP_BOOST = -100.0  # Extra boost when jumping with someone on head
const WALL_SLIDE_SPEED = 60.0
const SWIM_SPEED = 100.0
const SWIM_UP_SPEED = 200.0
const WATER_GRAVITY = 50.0
const BUOYANCY_FORCE = 30.0
const WATER_DRAG = 0.95

# Dash Constants
const DASH_SPEED = 600.0
const DASH_DURATION = 0.15
const DASH_COOLDOWN = 0.5
const DASH_SHADOW_INTERVAL = 0.03  # Spawn shadow every 0.03 seconds during dash

# Coyote time (air jump) Constants
const COYOTE_TIME = 0.15  # Time after leaving platform where player can still jump

# Fall management
var max_velocity_y = 0
const FALL_LIMIT = 1000

# Dash management
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var dash_direction = 0
var dash_shadow_timer = 0.0

# Coyote time management
var coyote_timer: float = 0.0  # Tracks time since leaving ground

# Death management
var is_dying: bool = false  # Prevent multiple death calls

# Cooperative jumping
var player_on_head: CharacterBody2D = null
var standing_on_player: CharacterBody2D = null
var ignore_collision_timer := 0.0  # Temporarily ignore player collisions after coop jump
const IGNORE_COLLISION_DURATION = 0.3

# Abilities - override in child classes
@export var can_swim: bool = false
@export var can_climb: bool = false
@export var can_push_rocks: bool = false
@export var can_wall_slide: bool = false
@export var can_dash: bool = false

# State management
var state: String = "idle"
var prev_state: String = ""
var facing_direction = 1

# Sound effects
var footstep_timer: float = 0.0
const FOOTSTEP_INTERVAL: float = 0.35  # Time between footstep sounds
var last_footstep_frame: int = 0
var swim_sound_timer: float = 0.0
const SWIM_SOUND_INTERVAL: float = 0.6  # Time between swim sounds
var previous_velocity_y: float = 0.0  # Track velocity for landing sound

# Environment tracking
var is_on_vine := false
var is_in_water := false
var held_rock: Node = null

# Camera limits
var camera_limit_left: int = -10000000
var camera_limit_right: int = 10000000
var camera_limit_top: int = -10000000
var camera_limit_bottom: int = 10000000

# Node references
@onready var camera_2d: Camera2D = $Camera2D
@onready var player_name: Label = $PlayerName
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_label: Label = $StateLabel
@onready var environment_label: Label = $EnvironmentLabel
@onready var head_ray_cast: RayCast2D = %HeadRayCast
@onready var foot_ray_cast: RayCast2D = %FootRayCast
@onready var right_ray_cast: RayCast2D = %RightRayCast
@onready var left_ray_cast: RayCast2D = %LeftRayCast
@onready var biome_background: Node = $Backgrounds
var face_ray_cast
var current_biome = null

# Particle effects
var swim_particles: GPUParticles2D = null


func _enter_tree() -> void:
	var authority_id = name.to_int()
	set_multiplayer_authority(authority_id)
	add_to_group("players")
	
	print("DEBUG: Player %s _enter_tree(), authority set to: %s, my peer ID: %s" % [name, authority_id, multiplayer.get_unique_id()])
	
	# Set player_id based on multiplayer ID
	# ID 1 is server/host (player 0), ID > 1 is client (player 1)
	if authority_id == 1:
		player_id = 0  # Host is Player 0
	else:
		player_id = 1  # Client is Player 1


func _ready() -> void:
	print("DEBUG: Player %s _ready() called, is_multiplayer_authority: %s" % [name, is_multiplayer_authority()])
	
	if is_multiplayer_authority():
		_setup_local_player()
	else:
		biome_background.visible = false
		# Disable camera for non-authority players
		if camera_2d:
			camera_2d.enabled = false
	
	for child in biome_background.get_children():
		child.visible = false
		child.modulate.a = 1.0
	
	# Create swim particle effect
	_create_swim_particles()
	
	# Auto-connect to all water areas in the scene
	_connect_to_water_areas()

func _process(_delta: float) -> void:
	if is_multiplayer_authority() and camera_2d and biome_background:
		# Make background follow camera's screen position, not player position
		biome_background.global_position = camera_2d.get_screen_center_position()


func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): 
		return
	
	# Update collision ignore timer
	if ignore_collision_timer > 0:
		ignore_collision_timer -= delta
		# Temporarily disable collision layer with other players
		if ignore_collision_timer <= 0:
			collision_mask |= (1 << 1)  # Re-enable player collision layer
	
	# Update footstep timer
	if footstep_timer > 0:
		footstep_timer -= delta
	
	# Update swim sound timer
	if swim_sound_timer > 0:
		swim_sound_timer -= delta
	
	# Update coyote timer
	if is_on_floor() or standing_on_player:
		coyote_timer = COYOTE_TIME  # Reset coyote time when on ground
	elif coyote_timer > 0:
		coyote_timer -= delta  # Count down when in air
	
	_track_fall()
	_update_player_detection()
	_update_animation()
	_update_raycasts()
	_update_environment_label()
	_handle_footsteps()  # Add footstep sound handling
	
	# Handle dash cooldown
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	
	# State machine
	match state:
		"idle":
			_state_idle()
		"move":
			_state_move()
		"jump":
			_state_jump(delta)
		"fall":
			_state_fall(delta)
		"hold_rock":
			_state_hold_rock(delta)
		"climb":
			_state_climb(delta)
		"swim":
			_state_swim(delta)
		"wall_slide":
			_state_wall_slide(delta)
		"wall_jump":
			_state_wall_jump(delta)
		"dash":
			_state_dash(delta)
	
	# Track previous velocity for landing sound detection
	previous_velocity_y = velocity.y


# ==============================================
# Player Detection for Cooperative Jumping
# ==============================================
#func _update_player_detection() -> void:
	## Don't detect players during collision ignore period OR when jumping
	#if ignore_collision_timer > 0 or state == "jump":
		#player_on_head = null
		#standing_on_player = null
		#return
	#
	## Check if someone is standing on our head
	#player_on_head = null
	#if head_ray_cast.is_colliding():
		#var collider = head_ray_cast.get_collider()
		#if collider and collider.is_in_group("players") and collider != self:
			## Only count if they're actually on our head (not jumping away)
			#if collider.global_position.y < global_position.y - 10:
				#player_on_head = collider
	#
	## Check if we're standing on another player
	#standing_on_player = null
	#if foot_ray_cast.is_colliding():
		#var collider = foot_ray_cast.get_collider()
		#if collider and collider.is_in_group("players") and collider != self:
			#standing_on_player = collider

func _update_player_detection() -> void:
	# Don't detect players during collision ignore period
	if ignore_collision_timer > 0:
		player_on_head = null
		standing_on_player = null
		return
	
	# Check if someone is standing on our head
	player_on_head = null
	if head_ray_cast.is_colliding():
		var collider = head_ray_cast.get_collider()
		if collider and collider.is_in_group("players") and collider != self:
			# Don't detect if either player is jumping
			if collider.state == "jump" or state == "jump":
				player_on_head = null
			elif collider.global_position.y < global_position.y - 10:
				player_on_head = collider
	
	# Check if we're standing on another player
	standing_on_player = null
	if foot_ray_cast.is_colliding():
		var collider = foot_ray_cast.get_collider()
		if collider and collider.is_in_group("players") and collider != self:
			# Don't detect if either player is jumping
			if collider.state == "jump" or state == "jump":
				standing_on_player = null
			else:
				standing_on_player = collider

func _can_jump() -> bool:
	# Can jump if on floor OR standing on another player (but not during collision ignore)
	# OR if coyote time is still active (recently left ground)
	if ignore_collision_timer > 0:
		return is_on_floor() or coyote_timer > 0
	return is_on_floor() or standing_on_player != null or coyote_timer > 0


# ==============================================
# Animation & Updates
# ==============================================
func _update_animation() -> void:
	if state != prev_state:
		_play_state_animation(state)
		state_label.text = state
		prev_state = state
	
	anim.flip_h = facing_direction < 0


func _update_raycasts() -> void:
	if facing_direction < 0:
		face_ray_cast = left_ray_cast
	else:
		face_ray_cast = right_ray_cast


func _update_environment_label() -> void:
	if ignore_collision_timer > 0:
		environment_label.text = "coop jumping!"
	elif player_on_head:
		environment_label.text = "carrying player"
	elif standing_on_player:
		environment_label.text = "on player"
	elif is_in_water:
		environment_label.text = "in water"
	elif _is_touching_wall():
		environment_label.text = "on wall"
	elif _is_facing_to_rock():
		environment_label.text = "facing rock"
	elif is_on_vine:
		environment_label.text = "on vine"
	elif is_on_floor():
		environment_label.text = "on floor"
	else:
		environment_label.text = "in air"


func _play_state_animation(new_state: String) -> void:
	anim.offset = Vector2.ZERO
	
	match new_state:
		"idle":
			anim.play("idle")
			anim.offset.y = -1
		"move":
			anim.play("run")
			anim.offset.y = 1
		"jump":
			anim.play("jump")
		"fall":
			anim.play("fall")
			anim.offset.x = 1
		"climb":
			anim.play("climb")
			anim.offset = Vector2(1, 0.5)
		"swim":
			if anim.sprite_frames.has_animation("swim"):
				anim.play("swim")
			else:
				anim.play("jump")
		"wall_slide":
			anim.play("wall_slide")
		"wall_jump":
			anim.play("dash")
		"dash":
			anim.play("dash")


# ==============================================
# State Machine
# ==============================================
func _state_idle() -> void:
	# Check transitions in priority order
	if is_in_water:
		state = "swim"
		return
	
	# Allow falling even with player on head
	if not _can_jump():
		state = "fall"
		return
	
	if Input.is_action_just_pressed(get_action("jump")):
		_perform_jump()
		return
	
	var direction = int(Input.get_axis(get_action("left"), get_action("right")))
	if direction != 0:
		state = "move"
		facing_direction = direction
		return
	
	if can_dash and Input.is_action_just_pressed(get_action("dash")) and dash_cooldown_timer <= 0:
		dash_direction = facing_direction
		state = "dash"
		dash_timer = DASH_DURATION
		return
	
	if can_push_rocks and _is_facing_to_rock() and Input.is_action_pressed(get_action("interact")):
		print("DEBUG: Player %s transitioning to hold_rock state!" % name)
		state = "hold_rock"
		return
	
	# Debug interaction check
	if can_push_rocks and Input.is_action_pressed(get_action("interact")):
		if face_ray_cast and face_ray_cast.is_colliding():
			var collider = face_ray_cast.get_collider()
			if collider:
				print("DEBUG: Player %s pressing interact, raycast hit: %s (groups: %s)" % [name, collider.name, collider.get_groups()])
			else:
				print("DEBUG: Player %s pressing interact, raycast hit unknown object" % name)
		else:
			print("DEBUG: Player %s pressing interact but raycast not colliding" % name)
	
	if can_climb and is_on_vine and Input.is_action_pressed(get_action("up")):
		state = "climb"
		return
	
	# Catch falling player on head (only when not ignoring collisions)
	if player_on_head and player_on_head.velocity.y > 0 and ignore_collision_timer <= 0:
		player_on_head._caught()
	
	velocity.x = move_toward(velocity.x, 0, MOVE_SPEED)
	move_and_slide()


func _state_move() -> void:
	if is_in_water:
		state = "swim"
		return
	
	if not _can_jump():
		state = "fall"
		return
	
	if Input.is_action_just_pressed(get_action("jump")):
		_perform_jump()
		return
	
	var direction = int(Input.get_axis(get_action("left"), get_action("right")))
	if direction == 0:
		state = "idle"
		return
	
	facing_direction = direction
	
	if can_dash and Input.is_action_just_pressed(get_action("dash")) and dash_cooldown_timer <= 0:
		dash_direction = facing_direction
		state = "dash"
		dash_timer = DASH_DURATION
		return
	
	velocity.x = facing_direction * MOVE_SPEED
	
	if can_push_rocks and _is_facing_to_rock() and Input.is_action_pressed(get_action("interact")):
		print("DEBUG: Player %s transitioning to hold_rock from move state!" % name)
		state = "hold_rock"
		return
	
	if can_climb and is_on_vine and Input.is_action_pressed(get_action("up")):
		state = "climb"
		return
	
	# Catch falling player on head (only when not ignoring collisions)
	if player_on_head and player_on_head.velocity.y > 0 and ignore_collision_timer <= 0:
		player_on_head._caught()
	
	move_and_slide()


func _state_jump(delta: float) -> void:
	if is_in_water:
		state = "swim"
		return
	
	velocity += get_gravity() * delta
	
	if velocity.y >= 0:
		state = "fall"
		return
	
	if can_climb and is_on_vine and Input.is_action_pressed(get_action("up")):
		state = "climb"
		return
	
	var direction = int(Input.get_axis(get_action("left"), get_action("right")))
	if direction != 0:
		facing_direction = direction
	
	if can_dash and Input.is_action_just_pressed(get_action("dash")) and dash_cooldown_timer <= 0:
		dash_direction = facing_direction
		state = "dash"
		dash_timer = DASH_DURATION
		return
	
	velocity.x = direction * MOVE_SPEED
	
	move_and_slide()


func _state_fall(delta: float) -> void:
	if is_in_water:
		state = "swim"
		return
	
	velocity += get_gravity() * delta
	
	if _can_jump():
		# Play landing sound when hitting the ground
		# Use previous_velocity_y since velocity gets reset on landing
		print("⬇️ Landing check - previous_velocity_y: %.1f" % previous_velocity_y)
		if previous_velocity_y > 50:  # Lowered threshold from 100 to 50
			SoundManager.play_sound("land", -8.0, randf_range(0.95, 1.05))
			print("🔊 %s landed with sound (velocity was: %.1f)" % [name, previous_velocity_y])
		state = "idle"
		return
	
	# Allow jumping from another player's head while falling
	if standing_on_player and Input.is_action_just_pressed(get_action("jump")):
		_perform_jump()
		print("%s used %s's head to jump!" % [name, standing_on_player.name])
		return
	
	if can_climb and is_on_vine and Input.is_action_pressed(get_action("up")):
		state = "climb"
		return
	
	var direction = int(Input.get_axis(get_action("left"), get_action("right")))
	if direction != 0:
		facing_direction = direction
	
	# Check wall contact for wall slide
	if can_wall_slide:
		var wall_side = _is_touching_wall()
		if wall_side != 0 and direction == wall_side:
			state = "wall_slide"
			return
	
	if can_dash and Input.is_action_just_pressed(get_action("dash")) and dash_cooldown_timer <= 0:
		dash_direction = facing_direction
		state = "dash"
		dash_timer = DASH_DURATION
		return
	
	velocity.x = direction * MOVE_SPEED
	
	move_and_slide()

func _perform_jump() -> void:
	"""Handles cooperative jumping mechanics"""
	var jump_power = JUMP_VELOCITY
	
	# Reset coyote timer when jumping (prevent double jump)
	coyote_timer = 0.0
	
	# Play jump sound
	SoundManager.play_sound("jump_variation", -1.0, randf_range(0.95, 1.05))
	
	# If someone is on our head, perform cooperative jump
	if player_on_head:
		# Store reference before disabling collision
		var top_player = player_on_head
		
		collision_layer = 0  # Disable this player's collision entirely
		top_player.collision_layer = 0
		
		# Then re-enable after timer in _physics_process():
		if ignore_collision_timer <= 0:
			collision_layer = 2  # Or whatever your player layer is
		
		## Clear the player_on_head IMMEDIATELY to prevent repeat calls
		#player_on_head = null
		#
		## CRITICAL: Disable collision between players temporarily
		#ignore_collision_timer = IGNORE_COLLISION_DURATION
		#collision_mask &= ~(1 << 1)
		#
		## Also disable collision for top player
		#if top_player.has_method("_start_coop_jump"):
			#top_player._start_coop_jump()
		#
		## Push top player up slightly to separate them
		#top_player.global_position.y -= 5
		#
		## Set velocities for both players
		#velocity.y = JUMP_VELOCITY
		#top_player.velocity.y = JUMP_VELOCITY + COOP_JUMP_BOOST
		#top_player.state = "jump"
		
		print("%s launched %s! Bottom: %.1f, Top: %.1f" % [name, top_player.name, velocity.y, top_player.velocity.y])
	else:
		# Normal jump
		velocity.y = jump_power
	
	# If we're standing on another player, notify them
	if standing_on_player:
		print("%s jumped off %s's head!" % [name, standing_on_player.name])
		standing_on_player = null  # Clear this too
	
	state = "jump"  # MUST transition to jump state

func _start_coop_jump() -> void:
	"""Called by the bottom player to sync the coop jump"""
	ignore_collision_timer = IGNORE_COLLISION_DURATION
	collision_mask &= ~(1 << 1)  # Disable player collision layer


func _state_wall_slide(delta: float) -> void:
	if not can_wall_slide:
		state = "fall"
		return
	
	# Slow down vertical velocity
	velocity.y = min(velocity.y + get_gravity().y * delta, WALL_SLIDE_SPEED)
	
	var direction = int(Input.get_axis(get_action("left"), get_action("right")))
	var wall_side = _is_touching_wall()
	
	if wall_side == 0:
		state = "fall"
		return
	
	# Only keep sliding if pressing INTO the wall
	if direction != wall_side:
		state = "fall"
		if direction != 0:
			facing_direction = direction
		return
	
	# Wall jump
	if Input.is_action_just_pressed(get_action("jump")):
		# Play wall jump sound
		SoundManager.play_sound("jump_variation", -1.0, randf_range(0.95, 1.05))
		
		velocity.x = JUMP_VELOCITY * wall_side * 0.25
		velocity.y = JUMP_VELOCITY * 1.1
		state = "wall_jump"
		if wall_side != 0:
			facing_direction = -wall_side
		return
	
	# Land
	if is_on_floor():
		state = "idle"
		return
	
	move_and_slide()


func _state_wall_jump(delta: float) -> void:
	if velocity.y > 0:
		state = "fall"
		return
	
	if velocity.y > -200:
		var direction = int(Input.get_axis(get_action("left"), (get_action("right"))))
		if direction != 0:
			facing_direction = direction
		velocity.x = direction * MOVE_SPEED
	
	velocity += get_gravity() * delta
	
	if can_dash and Input.is_action_just_pressed(get_action("dash")) and dash_cooldown_timer <= 0:
		dash_direction = facing_direction
		state = "dash"
		dash_timer = DASH_DURATION
		return
	
	# Check if touching wall again
	if can_wall_slide and _is_touching_wall() and facing_direction == -get_wall_normal().x:
		state = "wall_slide"
		return
	
	move_and_slide()


func _state_dash(delta: float) -> void:
	if not can_dash:
		state = "fall"
		return
	
	# Play dash sound at the start
	if dash_timer == DASH_DURATION:
		SoundManager.play_sound("dash", 1.0, randf_range(0.95, 1.05))
		dash_shadow_timer = 0.0  # Reset shadow timer at start
	
	if dash_timer <= 0:
		dash_cooldown_timer = DASH_COOLDOWN
		if is_on_floor():
			state = "idle"
		else:
			state = "fall"
		return
	
	# Spawn shadow effects during dash
	dash_shadow_timer -= delta
	if dash_shadow_timer <= 0:
		_create_dash_shadow()
		dash_shadow_timer = DASH_SHADOW_INTERVAL
	
	# Apply dash velocity
	velocity.x = dash_direction * DASH_SPEED
	velocity.y = 0  # ignore gravity while dashing
	dash_timer -= delta
	
	move_and_slide()


func _state_swim(delta: float) -> void:
	if not is_in_water:
		# Stop swim particles when exiting water
		if swim_particles:
			swim_particles.emitting = false
		
		if is_on_floor():
			state = "idle"
		else:
			state = "fall"
		return
	
	# Non-swimmers sink
	if not can_swim:
		# Stop particles for non-swimmers
		if swim_particles:
			swim_particles.emitting = false
		
		velocity += get_gravity() * delta * 1.5
		velocity.y = min(velocity.y, FALL_SPEED)
		
		if is_on_floor() and is_in_water:
			_die()  # Drowned
		
		move_and_slide()
		return
	
	# Swimming controls
	var direction = Input.get_axis(get_action("left"), get_action("right"))
	var vertical = Input.get_axis(get_action("down"), get_action("up"))
	
	# Activate swim particles when moving
	var is_moving = direction != 0 or vertical != 0
	if swim_particles:
		swim_particles.emitting = is_moving
	
	# Play swim sound when moving
	if is_moving and swim_sound_timer <= 0:
		SoundManager.play_sound("swim", -8.0, randf_range(0.9, 1.1))
		swim_sound_timer = SWIM_SOUND_INTERVAL
	
	if direction != 0:
		facing_direction = int(direction)
		velocity.x = direction * SWIM_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SWIM_SPEED * 2)
	
	if vertical != 0:
		velocity.y = -vertical * SWIM_UP_SPEED
	else:
		velocity.y += WATER_GRAVITY * delta
		velocity.y -= BUOYANCY_FORCE * delta
	
	velocity *= WATER_DRAG
	velocity.y = clamp(velocity.y, -SWIM_UP_SPEED, SWIM_UP_SPEED)
	
	move_and_slide()


func _state_hold_rock(delta: float) -> void:
	if not can_push_rocks:
		state = "idle"
		return
	
	# Drop rock if interact button released
	if not Input.is_action_pressed(get_action("interact")):
		held_rock = null
		state = "idle"
		return
	
	# If not already holding, try to grab one
	if held_rock == null:
		if face_ray_cast.is_colliding():
			var collider = face_ray_cast.get_collider()
			if collider and collider.is_in_group("pushable"):
				held_rock = collider
				print("DEBUG: Player %s grabbed rock: %s" % [name, collider.name])
			else:
				state = "idle"
				return
		else:
			state = "idle"
			return
	
	# Once holding, only check if rock still exists and is nearby
	# Don't rely on raycast while moving (it can lose contact temporarily)
	if held_rock == null or not is_instance_valid(held_rock):
		print("DEBUG: Player %s lost rock reference" % name)
		held_rock = null
		state = "idle"
		return
	
	# Check if rock is too far away (using distance instead of raycast)
	var distance_to_rock = global_position.distance_to(held_rock.global_position)
	if distance_to_rock > 60:  # Increased tolerance for pushing
		print("DEBUG: Player %s rock too far: %f" % [name, distance_to_rock])
		held_rock = null
		state = "idle"
		return
	
	var input_dir = int(Input.get_axis(get_action("left"), get_action("right")))
	
	if input_dir != 0:
		# Don't update facing direction when holding rock - keep original facing direction
		
		# Move player at consistent speed
		velocity.x = input_dir * (MOVE_SPEED * 0.6)
		
		# Move rock at same speed to maintain contact
		var rock_vel = Vector2(input_dir * (MOVE_SPEED * 0.6), 0)
		_move_rock.rpc(held_rock.get_path(), rock_vel, delta)
		
		if input_dir == facing_direction:
			anim.play("push")
		elif input_dir == -facing_direction:
			anim.play("pull")
	else:
		velocity.x = 0
		anim.play("hold")
	
	move_and_slide()


func _state_climb(delta: float) -> void:
	if not can_climb:
		state = "fall"
		return
	
	if Input.is_action_just_pressed(get_action("jump")):
		velocity.y = JUMP_VELOCITY
		state = "jump"
		return
	
	var direction = Input.get_axis(get_action("left"), get_action("right"))
	if direction != 0:
		state = "move"
		facing_direction = int(direction)
		return
	
	if not is_on_vine:
		state = "fall"
		return
	
	velocity = Vector2.ZERO
	var input = Input.get_axis(get_action("down"), get_action("up"))
	
	if input != 0:
		velocity.y = input * -MOVE_SPEED * 0.6
		position.y += velocity.y * delta
		
		# Play climbing footstep sounds
		if footstep_timer <= 0:
			SoundManager.play_sound("footstep", 3.0, randf_range(0.95, 1.05))
			footstep_timer = FOOTSTEP_INTERVAL
		
		if input > 0:
			anim.play()
		else:
			anim.play_backwards()
	else:
		anim.pause()
	
	move_and_slide()


# ==============================================
# Support Functions
# ==============================================
func _handle_footsteps() -> void:
	"""Play footstep sounds when moving on the ground"""
	# Only play footsteps when in move state and on ground
	if state == "move" and is_on_floor() and footstep_timer <= 0:
		# Determine which footstep sound to play based on environment
		var footstep_sound = "footstep"
		
		# You can add biome detection here later
		# For now, use default footstep sounds
		
		SoundManager.play_sound(footstep_sound, 3.0, randf_range(0.9, 1.1))
		footstep_timer = FOOTSTEP_INTERVAL


func _create_dash_shadow() -> void:
	"""Create a shadow/afterimage effect during dash"""
	if not is_multiplayer_authority():
		return
	
	# Create a sprite that looks like the player
	var shadow = Sprite2D.new()
	shadow.texture = anim.sprite_frames.get_frame_texture(anim.animation, anim.frame)
	shadow.flip_h = anim.flip_h
	shadow.offset = anim.offset
	shadow.global_position = anim.global_position
	
	# Make shadow more visible with a colored tint
	# Cyan/blue tint with higher opacity for better visibility
	shadow.modulate = Color(1.0, 1.0, 1.0, 0.7)  # Bright cyan, more opaque
	shadow.z_index = 1  # Behind the player
	
	# Add to the scene (parent's parent to avoid moving with player)
	get_parent().add_child(shadow)
	
	# Fade out faster for cleaner trail effect
	var tween = create_tween()
	tween.tween_property(shadow, "modulate:a", 0.0, 0.3)
	tween.tween_callback(shadow.queue_free)


func _is_touching_wall() -> int:
	if left_ray_cast.is_colliding():
		var left_object = left_ray_cast.get_collider()
		if left_object and not (left_object.is_in_group("players") or left_object.is_in_group("pushable")):
			return -1  # wall on left
	
	if right_ray_cast.is_colliding():
		var right_object = right_ray_cast.get_collider()
		if right_object and not (right_object.is_in_group("players") or right_object.is_in_group("pushable")):
			return 1   # wall on right
	
	return 0

func _track_fall() -> void:
	if state == "fall":
		max_velocity_y = max(max_velocity_y, velocity.y)
	elif state == "wall_slide":
		max_velocity_y = 0
	elif is_on_floor() or (standing_on_player and ignore_collision_timer <= 0):
		if max_velocity_y > FALL_LIMIT and not standing_on_player:
			_die()
		max_velocity_y = 0


func _caught() -> void:
	max_velocity_y = 0.0
	velocity.y = 0.0
	print("%s was saved!" % name)


func _die() -> void:
	# Prevent multiple death calls
	if is_dying:
		return
	
	is_dying = true
	
	# Play hurt sound with proper volume
	SoundManager.play_sound("hurt", -5.0, randf_range(0.95, 1.05))
	print("%s died!" % name)
	# Override in child classes for specific spawn points


func _is_facing_to_rock() -> bool:
	if face_ray_cast and face_ray_cast.is_colliding():
		var collider = face_ray_cast.get_collider()
		if collider and collider.is_in_group("pushable"):
			# Check if the rock is actually in front of the player
			var rock_direction = (collider.global_position - global_position).x
			var facing_matches = (facing_direction > 0 and rock_direction > 0) or (facing_direction < 0 and rock_direction < 0)
			
			if facing_matches:
				print("DEBUG: Player %s found pushable object: %s" % [name, collider.name])
				return true
	return false


func _is_still_holding_rock() -> bool:
	if held_rock == null:
		return false
	if not face_ray_cast.is_colliding():
		return false
	return face_ray_cast.get_collider() == held_rock


func _update_camera_limits() -> void:
	if camera_2d:
		camera_2d.limit_left = camera_limit_left
		camera_2d.limit_right = camera_limit_right
		camera_2d.limit_top = camera_limit_top
		camera_2d.limit_bottom = camera_limit_bottom
		print("%s camera limits updated: L:%d R:%d T:%d B:%d" % [name, camera_limit_left, camera_limit_right, camera_limit_top, camera_limit_bottom])

func _setup_local_player() -> void:
	if camera_2d:
		camera_2d.enabled = true
		camera_2d.make_current()
		camera_2d.position_smoothing_enabled = true
		camera_2d.position_smoothing_speed = 5.0
		_update_camera_limits()

# Call this function to set camera limits (called by Map script)
func set_camera_limits(left: int, right: int, top: int, bottom: int) -> void:
	camera_limit_left = left
	camera_limit_right = right
	camera_limit_top = top
	camera_limit_bottom = bottom
	_update_camera_limits()

func get_action(base_action: String) -> String:
	return base_action + "_p" + str(player_id)

@rpc("any_peer")
func _move_rock(path_to_collider, rock_velocity, _delta) -> void:
	if not path_to_collider:
		return
	var collider = get_node(path_to_collider)
	
	# Use the rock's velocity instead of directly modifying position
	# This allows the rock's physics to work properly (gravity, etc.)
	if collider.has_method("push"):
		# Use the push method if available
		var direction = sign(rock_velocity.x)
		collider.push(direction)
	else:
		# Fallback: set velocity directly
		collider.velocity.x = rock_velocity.x

@rpc("any_peer", "call_local")
func _set_on_moving_platform() -> void:
	# This makes the player above think they're on floor temporarily
	# So they can jump from the other player's head
	pass  # The physics engine handles this through collision

# ==============================================
# Background Management
# ==============================================
func show_biome_background(biome_name: String) -> void:
	var bg = biome_background.get_node_or_null(biome_name + "Background")
	if bg:
		bg.modulate.a = 1.0
		
		if current_biome and current_biome != bg:
			bg.visible = true
			
			var old_anim = current_biome.get_node_or_null("AnimationPlayer")
			var new_anim = bg.get_node_or_null("AnimationPlayer")
			
			if old_anim:
				old_anim.play('fade_out')
			
			if new_anim:
				new_anim.play('fade_in')
			
			if old_anim:
				await old_anim.animation_finished
			current_biome.visible = false
		else:
			bg.visible = true
			var new_anim = bg.get_node_or_null("AnimationPlayer")
			if new_anim:
				new_anim.play("RESET")
				new_anim.seek(0.5, true)
		
		current_biome = bg
	else:
		print("No background found for biome: %s" % biome_name)


# ==============================================
# Vine Detection
# ==============================================
# Keep existing body signals for TileMap vines
func _on_vine_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("climbable"):
		is_on_vine = true
		print("Detected climbable body (TileMap vine)")

func _on_vine_detector_body_exited(body: Node2D) -> void:
	if body.is_in_group("climbable"):
		is_on_vine = false
		print("Exited climbable body (TileMap vine)")

# ADD THESE NEW FUNCTIONS for Area2D detection (like ladder)
func _on_vine_detector_area_entered(area: Area2D) -> void:
	if area.is_in_group("climbable"):
		is_on_vine = true
		print("Detected climbable area (Ladder)")

func _on_vine_detector_area_exited(area: Area2D) -> void:
	if area.is_in_group("climbable"):
		is_on_vine = false
		print("Exited climbable area (Ladder)")


# ==============================================
# Water Detection (Auto-connect method)
# ==============================================
func _create_swim_particles() -> void:
	"""Create particle effect for swimming"""
	swim_particles = GPUParticles2D.new()
	swim_particles.emitting = false
	swim_particles.amount = 20
	swim_particles.lifetime = 0.8
	swim_particles.one_shot = false
	swim_particles.explosiveness = 0.0
	swim_particles.randomness = 0.5
	swim_particles.visibility_rect = Rect2(-50, -50, 100, 100)
	
	# Create particle material
	var particle_material = ParticleProcessMaterial.new()
	
	# Emission
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_material.emission_sphere_radius = 15.0
	
	# Direction and spread
	particle_material.direction = Vector3(0, -1, 0)
	particle_material.spread = 45.0
	particle_material.initial_velocity_min = 30.0
	particle_material.initial_velocity_max = 60.0
	
	# Gravity and damping
	particle_material.gravity = Vector3(0, 50, 0)
	particle_material.damping_min = 20.0
	particle_material.damping_max = 40.0
	
	# Scale
	particle_material.scale_min = 2.0
	particle_material.scale_max = 4.0
	
	# Color - light blue/cyan for water bubbles
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.5, 0.8, 1.0, 0.8))  # Start: light blue, opaque
	gradient.add_point(1.0, Color(0.3, 0.6, 1.0, 0.0))  # End: darker blue, transparent
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	particle_material.color_ramp = gradient_texture
	
	swim_particles.process_material = particle_material
	swim_particles.z_index = 5  # Above player
	
	add_child(swim_particles)


func _connect_to_water_areas() -> void:
	# Find all water areas in the scene and connect to them
	await get_tree().process_frame  # Wait one frame to ensure scene is loaded
	
	var water_areas = get_tree().get_nodes_in_group("water")
	for water in water_areas:
		if water is Area2D:
			if not water.body_entered.is_connected(_on_water_area_entered):
				water.body_entered.connect(_on_water_area_entered)
			if not water.body_exited.is_connected(_on_water_area_exited):
				water.body_exited.connect(_on_water_area_exited)
	
	print("%s connected to %d water areas" % [name, water_areas.size()])


func _on_water_area_entered(body: Node2D) -> void:
	if body == self:
		is_in_water = true
		print("%s entered water" % name)
		# Particle will be activated when swimming/moving


func _on_water_area_exited(body: Node2D) -> void:
	if body == self:
		is_in_water = false
		print("%s exited water" % name)
		# Stop particles when leaving water
		if swim_particles:
			swim_particles.emitting = false
