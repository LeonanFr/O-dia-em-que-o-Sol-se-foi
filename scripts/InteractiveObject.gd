extends StaticBody3D
class_name InteractiveObject

signal interacted(object_id: String)

enum LightRequirement {NONE, CELLPHONE, FLASHLIGHT}

@export var inspection_scale_multiplier: float = 1.0
@export var is_inspectable: bool = false
@export var item_data: ItemData
@export var required_light: LightRequirement = LightRequirement.NONE
@export var required_focus_id: String = ""
@export var is_container: bool = false
@export var collision_shape: CollisionShape3D

func get_focus_transform():
	return null

func interact(_action: String = "") -> void:
	if item_data:
		emit_signal("interacted", item_data.id)
	else:
		print_debug("Objeto interativo não possui ItemData atribuído: ", name)
		
func use_tool(_tool_data: ItemData) -> bool:
	GameManager.emit_notification_requested("Não funciona.")
	return false
	
func is_light_requirement_met() -> bool:
	match required_light:
		LightRequirement.NONE:
			return true
		LightRequirement.CELLPHONE:
			return GameManager.is_direct_use_item_active("cellphone") or GameManager.is_direct_use_item_active("charged_flashlight")
		LightRequirement.FLASHLIGHT:
			return GameManager.is_direct_use_item_active("charged_flashlight")
	return false
	
func handle_inspection_click(_raycast_result: Dictionary):
	pass
	
func on_inspection_start():
	pass

func on_inspection_stop():
	pass
