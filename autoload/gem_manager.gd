extends Node

# Gem collection state
var red_gem_collected: bool = false
var blue_gem_collected: bool = false

# Signals for door updates
signal gems_state_changed(red_collected: bool, blue_collected: bool)
signal door_should_open

# Called when a gem is collected
@rpc("any_peer", "call_local", "reliable")
func collect_gem(gem_type: String, player_authority: int):
	var collector_id = multiplayer.get_remote_sender_id()
	if collector_id == 0:  # local call
		collector_id = multiplayer.get_unique_id()
	
	print("Gem collected - Type: %s by Player ID: %d (authority: %d)" % [gem_type, collector_id, player_authority])
	
	# Determine if this is the correct player based on gem type and collector
	var is_valid_collection = false
	
	if gem_type == "red":
		# Red gem should only be collected by player_0 (host with ID 1)
		is_valid_collection = (collector_id == 1)
		if is_valid_collection:
			red_gem_collected = true
	elif gem_type == "blue":
		# Blue gem should only be collected by player_1 (client with ID != 1) 
		is_valid_collection = (collector_id != 1)
		if is_valid_collection:
			blue_gem_collected = true
	
	if not is_valid_collection:
		print("Invalid gem collection attempt! Player %d tried to collect %s gem" % [collector_id, gem_type])
		return
	
	# Play gem collection sound
	SoundManager.play_sound("gem_pick", -5.0, randf_range(0.95, 1.05))
	
	print("Valid gem collection! %s gem collected by player %d" % [gem_type, collector_id])
	
	# Broadcast state change
	gems_state_changed.emit(red_gem_collected, blue_gem_collected)
	
	# Check if door should open
	if red_gem_collected and blue_gem_collected:
		door_should_open.emit()
		print("Both gems collected! Door should open.")

# Check if both gems are collected
func are_both_gems_collected() -> bool:
	return red_gem_collected and blue_gem_collected

# Reset gems (for testing or level restart)
func reset_gems():
	red_gem_collected = false
	blue_gem_collected = false
	gems_state_changed.emit(red_gem_collected, blue_gem_collected)