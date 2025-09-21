extends StaticBody3D
class_name InteractiveObject

signal interacted(object_id: String)

enum LightRequirement {NONE, CELLPHONE, FLASHLIGHT}

@export var required_light: LightRequirement = LightRequirement.NONE
@export var object_id: String = ""
@export var required_focus_id: String = ""
@export var is_container: bool = false
@export var collision_shape: CollisionShape3D
@export var is_collectible: bool = false

func get_focus_transform():
	return null

func interact(action: String = "") -> void:
	emit_signal("interacted", object_id)
