extends ItemData
class_name FlashlightItemData

@export var required_batteries: int = 2
var current_batteries: int = 0
@export var charged_flashlight_item: Resource

func add_battery() -> bool:
	current_batteries += 1
	if current_batteries >= required_batteries:
		var charged_item = charged_flashlight_item.duplicate()
		GameManager.add_to_inventory(charged_item)
		GameManager.remove_from_inventory(self.id)
		GameManager.emit_notification_requested("Lanterna carregada!")
		GameManager.remove_from_inventory("cellphone")
		if GameManager.is_cellphone_light_on:
			GameManager.toggle_cellphone_light() 
		return true
	else:
		GameManager.emit_notification_requested("Coloque mais uma bateria.")
		return false
