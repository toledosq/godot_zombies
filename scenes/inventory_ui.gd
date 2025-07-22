extends Control

signal inventory_opened
signal inventory_closed

func _ready():
	visible = false

func _input(event):
	if event.is_action_pressed("ui_inventory"):
		visible = not visible
		_update_mouse_mode()

func _update_mouse_mode():
	if visible:
		emit_signal("inventory_opened")
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		emit_signal("inventory_closed")
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
