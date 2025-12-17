extends CanvasLayer

@onready var dialog_panel = $Panel
@onready var dialog_label = $Panel/VBoxContainer/Label
@onready var next_button = $Panel/VBoxContainer/Button
@onready var animation_player = $AnimationPlayer

var content_array: Array[String] = []
var current_index: int = 0
var is_showing: bool = false

func _ready():
	dialog_panel.visible = false
	next_button.pressed.connect(_on_next_pressed)
	animation_player.animation_finished.connect(_on_animation_finished)

func _process(_delta: float) -> void:
	if (Input.is_action_just_pressed("interact_p0") or Input.is_action_just_pressed("interact_p1")) and is_showing:
		_on_next_pressed()
	return

func show_dialog(contents: Array[String]):
	if contents.is_empty():
		push_warning("Dialog content array is empty!")
		return
	
	if is_showing:
		return  # Prevent re-opening while dialog is active
	
	# Check if nodes are properly initialized
	if not dialog_panel:
		push_error("ERROR: dialog_panel is null!")
		return
	if not animation_player:
		push_error("ERROR: animation_player is null!")
		return
	
	content_array = contents.duplicate()  # Make a copy to avoid modifying the original array
	current_index = 0
	is_showing = true
	
	# Play UI open sound
	SoundManager.play_sound("ui_open", 10.0)
	
	dialog_panel.visible = true 
	dialog_panel.scale = Vector2(0, 0)  # Ensure we start from the correct scale
	update_dialog_content()
	animation_player.play("open")

func hide_dialog():
	# Play UI close sound
	SoundManager.play_sound("ui_close", 10.0)
	animation_player.play("close")
	# is_showing will be set to false when animation finishes

func hide_dialog_instant():
	dialog_panel.visible = false
	is_showing = false

func update_dialog_content():
	if current_index >= content_array.size():
		return
	
	# Update label text
	dialog_label.text = content_array[current_index]
	
	# Update button text
	if current_index >= content_array.size() - 1:
		next_button.text = "Close"
	else:
		next_button.text = "Next"

func _on_next_pressed():
	# Play UI click sound for next/close button
	SoundManager.play_sound("ui_click", 1.0)
	
	current_index += 1
	
	if current_index >= content_array.size():
		# Reached the end, close dialog
		hide_dialog()
		current_index = 0
		content_array.clear()
	else:
		# Show next content
		update_dialog_content()

func _on_animation_finished(anim_name: String):
	if anim_name == "close":
		dialog_panel.visible = false
		dialog_panel.scale = Vector2(0, 0)  # Reset scale for next opening
		is_showing = false
