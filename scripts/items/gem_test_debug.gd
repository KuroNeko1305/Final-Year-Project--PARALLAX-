extends Node2D

# Debug script for testing gem system in introduction folder
func _ready():
	print("=== Introduction Gem System Test ===")
	
	# Check GemManager
	if has_node("/root/GemManager"):
		var gem_manager = get_node("/root/GemManager")
		print("✓ GemManager loaded")
		gem_manager.gems_state_changed.connect(_on_gems_changed)
		gem_manager.door_should_open.connect(_on_door_opens)
	else:
		print("✗ GemManager not found")
	
	# Check multiplayer setup
	var player_id = multiplayer.get_unique_id()
	print("Player ID: %d" % player_id)
	print("Is server: %s" % multiplayer.is_server())
	
	# Find players in scene
	var players = get_tree().get_nodes_in_group("players")
	print("Found %d players in scene:" % players.size())
	for player in players:
		print("  - %s (Authority: %d)" % [player.name, player.get_multiplayer_authority()])

func _on_gems_changed(red_collected: bool, blue_collected: bool):
	print("🔴 Red gem: %s | 🔵 Blue gem: %s" % ["✓" if red_collected else "✗", "✓" if blue_collected else "✗"])

func _on_door_opens():
	print("🚪 DOOR UNLOCKED! Both gems collected!")

# Manual testing - press Enter to simulate gem collection
func _input(event):
	if event.is_action_pressed("ui_accept"):
		print("=== Manual Test ===")
		if has_node("/root/GemManager"):
			var gem_manager = get_node("/root/GemManager")
			# Simulate both gems being collected
			gem_manager.collect_gem.rpc("red", 1)
			gem_manager.collect_gem.rpc("blue", 2)