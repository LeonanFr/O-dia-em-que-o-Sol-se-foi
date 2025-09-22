extends Panel
class_name InventorySlot

signal used(slot: InventorySlot)

@onready var icon_rect = $Icon
@onready var quantity_label = $QuantityLabel
var slot_data: InventorySlotData = null

func display_item(data: InventorySlotData):
	slot_data = data
	icon_rect.texture = data.item.icon
	if data.quantity > 1:
		quantity_label.text = "x%d" % data.quantity
		quantity_label.show()
	else:
		quantity_label.hide()
	icon_rect.show()

func clear_slot():
	slot_data = null
	icon_rect.hide()
	quantity_label.hide()

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if slot_data:
			emit_signal("used", self)
