extends CanvasLayer

@onready var wait_label: Label = $PauseContainer/WaitLabel
@onready var continue_btn: Button = $PauseContainer/ContinueBtn
@onready var settings_menu = $SettingMenu

var pause_owner_id: int = -1

func _ready() -> void:
	hide()
	if settings_menu:
		settings_menu.visibility_changed.connect(_on_settings_closed)

func _input(event):
	if event.is_action_pressed("esc"):
		if get_tree().paused:
			# Only the pause owner can unpause
			if multiplayer.get_unique_id() == pause_owner_id:
				_unpause_game()
		else:
			_pause_game(multiplayer.get_unique_id())


# --------------------
# Main logic
# --------------------

func _pause_game(by_player_id: int) -> void:
	pause_owner_id = by_player_id
	get_tree().paused = true
	
	# Play UI open sound
	SoundManager.play_sound("ui_open", -5.0)
	
	show()

	# Update UI for both players
	if multiplayer.get_unique_id() == pause_owner_id:
		# You are the one who paused
		continue_btn.visible = true
		continue_btn.disabled = false
		wait_label.visible = false
	else:
		# Other player waits
		continue_btn.visible = true
		continue_btn.disabled = true
		wait_label.visible = true
		wait_label.text = "Waiting for %s..." % _get_player_name(by_player_id)

func _unpause_game() -> void:
	# Play UI close sound
	SoundManager.play_sound("ui_close", -5.0)
	
	get_tree().paused = false
	hide()
	pause_owner_id = -1


# --------------------
# Button events
# --------------------

func _on_continue_btn_pressed():
	if multiplayer.get_unique_id() == pause_owner_id:
		_unpause_game()


func _on_back_btn_pressed():
	if multiplayer.get_unique_id() == pause_owner_id:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://menus/scenes/main_menu.tscn")


# --------------------
# Helper
# --------------------

func _get_player_name(id) -> String:
	# Replace with however you store player names
	# Example: Global.players[id].name if you have a global player list
	if id.to_int() == 1:
		return GlobalIntroduction.player_0_name
	else:
		return GlobalIntroduction.player_1_name

func _on_setting_btn_pressed() -> void:
	# Play UI open sound
	SoundManager.play_sound("ui_open", -5.0)
	
	hide()  
	
	# Get player index (0 for host, 1 for guest)
	var player_index = 0 if multiplayer.is_server() else 1
	
	if settings_menu:
		settings_menu.show_settings(player_index)

func _on_settings_closed():
	if not settings_menu.visible:
		# Settings was closed, show pause menu again
		show()
