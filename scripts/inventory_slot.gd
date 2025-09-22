extends Panel
class_name InventorySlot

signal used(slot: InventorySlot)

@onready var icon_rect = $Icon
var item_data: ItemData = null

func display_item(data: ItemData):
	item_data = data
	icon_rect.texture = data.icon
	icon_rect.show()

func clear_slot():
	item_data = null
	icon_rect.hide()

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if item_data:
			emit_signal("used", self)
