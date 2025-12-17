# HelpBoard.gd - Attach this to an Area2D node
extends Area2D

# Export array of content pages
@export var help_pages: Array[String] = [
	"Welcome to the Help Board!",
	"Use WASD or Arrow Keys to move around.",
	"Press E to interact with objects.",
	"Press ESC to open the menu.",
	"Good luck on your adventure!"
]

@export var interaction_key: String = "interact_p0"  # E key or custom action

var player_in_range = false
var can_interact = true  # New flag to debounce interaction

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Hide UI elements initially
	$Label.visible = false
	$AnimatedSprite2D.visible = false
	
	# Validate help pages
	if help_pages.is_empty():
		help_pages = ["No content available."]

func _process(_delta):
	if player_in_range and can_interact and Input.is_action_just_pressed(interaction_key):
		if not Dialog.is_showing:
			interact()
			can_interact = false  # Prevent further interactions until dialog closes
			# Use a more reliable way to reset interaction - check dialog state periodically
			_start_dialog_check()

func interact():
	Dialog.show_dialog(help_pages)

func _on_body_entered(body):
	if body.is_in_group("players"):
		player_in_range = true
		# Show UI elements when player enters
		$Label.visible = true
		$AnimatedSprite2D.visible = true

func _on_body_exited(body):
	if body.is_in_group("players"):
		player_in_range = false
		can_interact = true  # Reset interaction when leaving the area
		# Hide UI elements when player exits
		$Label.visible = false
		$AnimatedSprite2D.visible = false

func _start_dialog_check():
	# Check dialog state periodically until it closes
	var timer = get_tree().create_timer(0.1)
	timer.timeout.connect(_check_dialog_closed)

func _check_dialog_closed():
	if not Dialog.is_showing:
		can_interact = true  # Re-enable interaction when dialog is closed
	else:
		# Keep checking if dialog is still showing
		_start_dialog_check()
