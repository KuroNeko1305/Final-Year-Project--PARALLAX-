extends Control

@onready var settings_menu = $SettingMenu
@onready var menu_history_stack: Array = [$MainMenuPopup/MainContainer]

func _ready() -> void:
	# Play menu music when entering main menu
	AudioManager.play_map_music("menu")

func _on_play_btn_pressed() -> void:
	SoundManager.play_sound("ui_click", -5.0)
	var play_container: VBoxContainer = $MainMenuPopup/PlayContainer
	play_container.visible = true
	menu_history_stack[-1].visible = false
	menu_history_stack.append(play_container)


func _on_host_btn_pressed() -> void:
	SoundManager.play_sound("ui_click", -5.0)
	var host_container: VBoxContainer = $MainMenuPopup/HostContainer
	host_container.visible = true
	menu_history_stack[-1].visible = false
	menu_history_stack.append(host_container)


func _on_join_btn_pressed() -> void:
	SoundManager.play_sound("ui_click", -5.0)
	var join_container: VBoxContainer = $MainMenuPopup/JoinContainer
	join_container.visible = true
	menu_history_stack[-1].visible = false
	menu_history_stack.append(join_container)


func _on_setting_btn_pressed() -> void:
	SoundManager.play_sound("ui_click", -5.0)
	settings_menu.show_settings()


func _on_exit_btn_pressed() -> void:
	SoundManager.play_sound("ui_click", -5.0)
	get_tree().quit()


func _on_back_btn_pressed() -> void:
	SoundManager.play_sound("ui_click", -5.0)
	menu_history_stack[-1].visible = false
	menu_history_stack.pop_back()
	menu_history_stack[-1].visible = true


# =======================================
# ONLY FOR HOST PLAYER
func _on_new_btn_pressed() -> void:
	SoundManager.play_sound("ui_click", -5.0)
	GlobalIntroduction.set_player_name(0, $MainMenuPopup/HostContainer/PlayerName.text)
	
	var results = NetworkHandler.start_server()
	var _ip = results[0]  # Prefixed with _ to avoid unused variable warning
	var _port = results[1]  # Prefixed with _ to avoid unused variable warning
	#NetworkHandler.start_client(ip, port)
	
	get_tree().change_scene_to_file("res://scenes/maps/introduction_map.tscn")
	#get_tree().change_scene_to_file("res://scenes/maps/chapter1.tscn")


func _on_continue_btn_pressed() -> void:
	SoundManager.play_sound("ui_click", -5.0)
	GlobalIntroduction.set_player_name(0, $MainMenuPopup/HostContainer/PlayerName.text)
	
	pass # Replace with function body.


# =======================================
# ONLY FOR JOIN PLAYER
func _on_connect_btn_pressed() -> void:
	SoundManager.play_sound("ui_click", -5.0)
	GlobalIntroduction.set_player_name(1, $MainMenuPopup/JoinContainer/PlayerName.text)
	
	var ip_server: LineEdit = $MainMenuPopup/JoinContainer/IPServer
	var port_server: LineEdit = $MainMenuPopup/JoinContainer/PortServer
	NetworkHandler.start_client(ip_server.text, int(port_server.text))
	#NetworkHandler.start_client()
	get_tree().change_scene_to_file("res://scenes/maps/introduction_map.tscn")
	#get_tree().change_scene_to_file("res://scenes/maps/chapter1.tscn")
