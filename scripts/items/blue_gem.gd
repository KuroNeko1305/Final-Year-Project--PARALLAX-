extends BaseGem

func _ready():
	gem_type = "blue" 
	target_player_authority = 2  # player_1 (client)
	super._ready()  # Call parent _ready
	
	# Add extra debug info for blue gem
	print("BLUE GEM DEBUG: Blue gem initialized at position: ", global_position)
	print("BLUE GEM DEBUG: Multiplayer ID: ", multiplayer.get_unique_id())
	print("BLUE GEM DEBUG: Target authority: ", target_player_authority)

func _process(_delta):
	# Periodic debug info (every 2 seconds)
	if Engine.get_process_frames() % 120 == 0:  # ~60fps * 2 = 120 frames
		print("BLUE GEM DEBUG: Visible: %s, Position: %s, Collected: %s" % [visible, global_position, is_collected])
