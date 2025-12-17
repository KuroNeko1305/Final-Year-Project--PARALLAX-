extends Area2D
class_name BaseGem

@export var gem_type: String = "" # "red" or "blue"
@export var target_player_authority: int = 1 # 1 for player_0, 2 for player_1

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var is_collected: bool = false

func _ready():
	# Connect the body entered signal
	body_entered.connect(_on_body_entered)
	
	# Set up visibility based on current player
	call_deferred("_setup_visibility")
	
	# Start idle animation
	if animation_player and animation_player.has_animation("idle"):
		animation_player.play("idle")

func _setup_visibility():
	# Only show gem to the correct player
	var current_player_id = multiplayer.get_unique_id()
	
	# Host has ID 1 and controls player_0 (authority 1)
	# Client has ID 2+ and controls player_1 (authority 2+)
	var should_be_visible = false
	
	if target_player_authority == 1:
		# Red gem - only visible to host (player_0)
		should_be_visible = (current_player_id == 1)
	elif target_player_authority >= 2:
		# Blue gem - only visible to clients (player_1) 
		should_be_visible = (current_player_id >= 2)
	
	visible = should_be_visible
	
	# Debug print
	print("Gem %s visibility for player %d: %s" % [gem_type, current_player_id, visible])

func _on_body_entered(body: Node2D):
	if is_collected:
		return
		
	# Check if it's a player
	if not body.is_in_group("players"):
		return
	
	# Only local player can collect gems
	if not body.is_multiplayer_authority():
		return
	
	# Check if gem should be visible to this player
	if not visible:
		print("Player tried to collect invisible gem %s - blocked!" % gem_type)
		return
	
	# Validate correct player for correct gem type
	var current_player_id = multiplayer.get_unique_id()
	var can_collect = false
	
	if gem_type == "red" and target_player_authority == 1:
		# Red gem - only player_0 (host with ID 1) can collect
		can_collect = (current_player_id == 1)
	elif gem_type == "blue" and target_player_authority >= 2:
		# Blue gem - only player_1 (clients with ID >= 2) can collect  
		can_collect = (current_player_id >= 2)
	
	if not can_collect:
		print("Wrong player tried to collect %s gem - blocked!" % gem_type)
		return
	
	collect_gem()

func collect_gem():
	if is_collected:
		return
		
	is_collected = true
	print("Collecting %s gem" % gem_type)
	
	# Play take animation if available
	if animation_player and animation_player.has_animation("take"):
		animation_player.play("take")
		# Wait for animation to finish before hiding
		await animation_player.animation_finished
	else:
		# Simple fade out if no take animation
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.3)
		await tween.finished
	
	# Hide the gem (animation should handle this but ensure it's hidden)
	hide()
	collision.disabled = true
	
	# Notify gem manager
	var player_authority = target_player_authority
	if has_node("/root/GemManager"):
		get_node("/root/GemManager").collect_gem.rpc(gem_type, player_authority)
