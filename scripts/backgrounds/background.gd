extends Node2D

@onready var cam := get_viewport().get_camera_2d()

func _ready():
	# Set all Parallax2D children to infinite repeat
	for child in get_children():
		if child is Parallax2D:
			child.repeat_times = 999
