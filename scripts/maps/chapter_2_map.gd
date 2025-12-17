extends "res://scripts/maps/map.gd"

# References to the two map views
@onready var winter_map = $WinterMap
@onready var autumn_map = $AutumnMap

# Collision layer bits
const AUTUMN_TILES_LAYER = 8  # Bit 3 (Layer 4) - AutumnMap tiles
const WINTER_TILES_LAYER = 16  # Bit 4 (Layer 5) - WinterMap tiles

func _ready():
	# Call parent _ready first
	super._ready()
	
	# Setup the collision layers for the tilemaps
	_setup_tilemap_collision_layers()
	
	# Setup visibility and collision based on local player
	_setup_map_visibility()


func _setup_tilemap_collision_layers() -> void:
	# Set AutumnMap tiles to collision layer 4 (bit 3, value 8)
	var autumn_frontmap = autumn_map.get_node_or_null("FrontMap")
	if autumn_frontmap and autumn_frontmap is TileMapLayer:
		var tileset = autumn_frontmap.tile_set
		if tileset:
			tileset.set_physics_layer_collision_layer(0, AUTUMN_TILES_LAYER)
			print("AutumnMap tiles set to collision layer 4 (value 8)")
	
	# Set WinterMap tiles to collision layer 5 (bit 4, value 16)
	var winter_frontmap = winter_map.get_node_or_null("FrontMap")
	if winter_frontmap and winter_frontmap is TileMapLayer:
		var tileset = winter_frontmap.tile_set
		if tileset:
			tileset.set_physics_layer_collision_layer(0, WINTER_TILES_LAYER)
			print("WinterMap tiles set to collision layer 5 (value 16)")


func _setup_map_visibility() -> void:
	# Wait for the local player to be spawned and get their player_id
	await get_tree().create_timer(0.5).timeout
	
	# Find the local player
	var local_player = _get_local_player()
	
	if local_player:
		var player_id = local_player.player_id
		
		# Player 0 sees Winter, Player 1 sees Autumn
		if player_id == 1:
			# Player_0 sees WinterMap only and collides with it
			winter_map.visible = false
			autumn_map.visible = true
			_set_player_collision_mask(local_player, AUTUMN_TILES_LAYER)
			print("Player_1 view: Showing AutumnMap, hiding WinterMap, colliding with AutumnMap")
		else:
			# Player_1 sees WinterMap only and collides with it
			winter_map.visible = true
			autumn_map.visible = false
			_set_player_collision_mask(local_player, WINTER_TILES_LAYER)
			print("Player_0 view: Showing WinterMap, hiding AutumnMap, colliding with WinterMap")
	else:
		# Fallback: show both if we can't determine
		print("WARNING: Could not find local player, showing both maps")
		winter_map.visible = true
		autumn_map.visible = true


func _set_player_collision_mask(player: CharacterBody2D, tile_layer: int) -> void:
	# Get the current collision mask
	var current_mask = player.collision_mask
	
	# Add the tile layer to the collision mask (bitwise OR)
	# First, remove both autumn and winter layers, then add the one we want
	current_mask &= ~AUTUMN_TILES_LAYER  # Remove autumn layer
	current_mask &= ~WINTER_TILES_LAYER  # Remove winter layer
	current_mask |= tile_layer  # Add the desired layer
	
	player.collision_mask = current_mask
	print("Player collision mask updated to: %d (includes layer %d)" % [current_mask, tile_layer])


func _get_local_player() -> Node:
	# Find the player that belongs to this client
	for node in get_tree().get_nodes_in_group("players"):
		if node.is_multiplayer_authority():
			return node
	return null


# Override the spawned signal handler to also update visibility when player spawns
func _on_player_spawned(node: Node) -> void:
	super._on_player_spawned(node)
	
	# If this is the local player, update visibility and collision
	if node.is_multiplayer_authority():
		_setup_map_visibility()
