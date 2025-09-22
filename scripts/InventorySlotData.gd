class_name InventorySlotData
extends RefCounted

var item: ItemData
var quantity: int

func _init(p_item: ItemData, p_quantity: int):
	item = p_item
	quantity = p_quantity
