extends ItemData
class_name FlashlightItemData

@export var required_batteries: int = 2
var current_batteries: int = 0
@export var charged_flashlight_item: Resource

func add_battery() -> bool:
	current_batteries += 1
	if current_batteries >= required_batteries:
		GameManager.emit_notification_requested("Lanterna carregada!")
		return true
	else:
		GameManager.emit_notification_requested("Coloque mais uma bateria.")
		return false
