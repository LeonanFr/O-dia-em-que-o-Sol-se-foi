extends StaticBody3D
class_name InteractiveObject

signal interacted(object_id: String)
@export var object_id: String = ""
@export var required_focus_id: String = ""

func get_focus_transform():
	return null

func interact(action: String = "") -> void:
	emit_signal("interacted", object_id)
