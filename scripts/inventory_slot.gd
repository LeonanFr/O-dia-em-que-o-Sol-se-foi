extends Panel
class_name InventorySlot

signal used(item_id: String)

@onready var icon_rect = $Icon
var item_id: String = ""

func display_item(id: String):
	item_id = id
	icon_rect.texture = load("res://assets/icons/" + id + ".png")
	icon_rect.show()

func clear_slot():
	item_id = ""
	icon_rect.hide()

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if item_id != "":
			emit_signal("used", item_id)
