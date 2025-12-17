extends PlayerBase

func _ready() -> void:
	# Set Player 0 abilities - wall slide specialist
	can_swim = false
	can_climb = false
	can_push_rocks = false
	can_wall_slide = true
	can_dash = true
	
	# Call parent ready
	super._ready()


func _setup_local_player() -> void:
	print("DEBUG: Player 0 _setup_local_player() called")
	# Call parent's camera setup first
	super._setup_local_player()
	
	# Then set player-specific properties
	player_name.text = GlobalIntroduction.player_0_name
	# Set position immediately, not deferred
	_set_spawn_position()


func _set_spawn_position() -> void:
	if GlobalIntroduction.spawn_points_0:
		global_position = GlobalIntroduction.spawn_points_0
		print("Player 0 positioned at spawn point: %s" % GlobalIntroduction.spawn_points_0)
	else:
		print("WARNING: Player 0 spawn point not set!")

func _die() -> void:
	# Call parent's _die() which handles the is_dying flag and plays sound
	super._die()
	
	# Only continue if this is the first death call (parent will set is_dying)
	if not is_dying:
		return
	
	print("%s respawning..." % name)
	
	# Reset death flag so player can die again
	is_dying = false
	
	# Reset position
	_set_spawn_position()
