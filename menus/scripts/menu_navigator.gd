extends Node
class_name MenuNavigator   # <- lets you add it easily in Inspector

var current_index := 0
var menu_items: Array[Node] = []

func set_menu(container: Container) -> void:
	menu_items = container.get_children()
	current_index = 0
	#if menu_items.size() > 0:
		#menu_items[current_index].grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if menu_items.is_empty():
		return
	
	if event.is_action_pressed("ui_down"):
		_move_focus(1)
	elif event.is_action_pressed("ui_up"):
		_move_focus(-1)
	elif event.is_action_pressed("ui_accept"):
		if menu_items[current_index] is LineEdit:
			_move_focus(1)
		else:
			menu_items[current_index].pressed.emit()
	elif event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _move_focus(direction: int):
	if menu_items.size() == 0: return
	current_index = (current_index + direction + menu_items.size()) % menu_items.size()
	menu_items[current_index].grab_focus()

func _on_back_pressed():
	# Override in child scene or connect this signal to go back
	#print("Back pressed - override _on_back_pressed in your menu")
	pass
