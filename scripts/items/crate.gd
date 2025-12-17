extends CharacterBody2D

@export var gravity = 900
@export var friction = 800
@export var push_speed = 100.0

# Water physics constants
@export var WATER_GRAVITY = 10.0
@export var BUOYANCY_FORCE = 280.0
@export var WATER_DRAG = 0.88
@export var SURFACE_DAMPING = 0.7

var is_in_water = false
var was_in_water = false  # Track if crate entered water (only reset on ground landing)
var was_on_floor: bool = false  # Track if crate was on floor last frame
var push_sound_timer: float = 0.0  # Timer for push sound
const PUSH_SOUND_INTERVAL: float = 0.4  # Time between push sounds

func _ready() -> void:
	_connect_to_water_areas()

func _connect_to_water_areas() -> void:
	await get_tree().process_frame
	
	var water_areas = get_tree().get_nodes_in_group("water")
	for water in water_areas:
		if water is Area2D:
			if not water.body_entered.is_connected(_on_water_area_entered):
				water.body_entered.connect(_on_water_area_entered)
			if not water.body_exited.is_connected(_on_water_area_exited):
				water.body_exited.connect(_on_water_area_exited)
	
	print("%s connected to %d water areas" % [name, water_areas.size()])

func _physics_process(delta):
	# Update push sound timer
	if push_sound_timer > 0:
		push_sound_timer -= delta
	
	# Store velocity before physics
	var velocity_before = velocity.y
	
	if is_in_water:
		_handle_water_physics(delta)
	else:
		_handle_normal_physics(delta)
	
	move_and_slide()
	
	# Check for landing sounds
	if is_on_floor():
		# Check if crate just landed (was in air, now on floor)
		if not was_on_floor and velocity_before > 100:  # Only if falling with some speed
			if is_in_water:
				# Play water splash sound when landing in water
				SoundManager.play_sound("water_land", 10.0, randf_range(0.9, 1.1))
				print("📦 Crate splashed into water (velocity: %.1f)" % velocity_before)
			else:
				# Play stone land sound (same as rock)
				SoundManager.play_sound("stone_land", -3.0, randf_range(0.9, 1.1))
				print("📦 Crate landed (velocity: %.1f)" % velocity_before)
		
		# Reset water entry flag when crate lands on solid ground (not in water)
		if not is_in_water:
			was_in_water = false
	
	# Store floor state for next frame
	was_on_floor = is_on_floor()

func _handle_normal_physics(delta):
	# SAME AS ROCK - Simple physics on land
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, friction * delta)

func _handle_water_physics(delta):
	# Apply weak downward force
	velocity.y += WATER_GRAVITY * delta
	
	# Strong buoyancy
	velocity.y -= BUOYANCY_FORCE * delta
	
	# Reduce buoyancy when floating up fast (anti-bobbing)
	if velocity.y < -30.0:
		velocity.y *= SURFACE_DAMPING
	
	# Clamp vertical velocity
	velocity.y = clamp(velocity.y, -120.0, 80.0)
	
	# Apply water drag
	velocity.x *= WATER_DRAG
	velocity.y *= WATER_DRAG
	
	# Horizontal friction
	velocity.x = move_toward(velocity.x, 0, friction * delta * 0.5)

func push(direction: float) -> void:
	if is_in_water:
		velocity.x = direction * push_speed * 0.6
	else:
		velocity.x = direction * push_speed
	
	# Play push sound with cooldown to avoid spam
	if push_sound_timer <= 0:
		SoundManager.play_sound("stone_push", 1.0)
		push_sound_timer = PUSH_SOUND_INTERVAL

func _on_water_area_entered(body):
	if body == self:
		is_in_water = true
		print("=== %s ENTERED WATER ===" % name)
		
		# Play water splash sound ONLY when first entering water (not re-entering)
		# Only if falling with significant velocity AND wasn't in water before
		if not was_in_water and velocity.y > 50.0:
			SoundManager.play_sound("water_land", -8.0, randf_range(0.9, 1.1))
			print("💦 %s splashed into water (velocity: %.1f)" % [name, velocity.y])
		
		was_in_water = true

func _on_water_area_exited(body):
	if body == self:
		is_in_water = false
		# Don't reset was_in_water here - only reset when landing on solid ground
		# This prevents sound spam when bouncing at water surface
		print("=== %s EXITED WATER ===" % name)
