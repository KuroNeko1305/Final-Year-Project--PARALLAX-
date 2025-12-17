extends Area2D

func _on_body_entered(body):
	if body.is_in_group("players") and body.is_multiplayer_authority():
		body.show_biome_background("Puzzle1")
