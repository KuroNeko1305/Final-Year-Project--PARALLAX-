extends StaticBody2D

@export_enum ("Winter", "Autumn") var type := 0

func _ready() -> void:
	# Set initial visibility based on type
	_update_visibility()

func _process(_delta: float) -> void:
	_update_visibility()

func _update_visibility():
	if type == 0:
		$Winter.visible = true
		$Autumn.visible = false
	else:
		$Winter.visible = false
		$Autumn.visible = true
