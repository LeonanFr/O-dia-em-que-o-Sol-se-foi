extends InteractiveObject
class_name Cellphone

var _is_picked_up: bool = false

func interact(action: String = "") -> void:
	if _is_picked_up:
		return

	if action == "pick_up":
		_is_picked_up = true
		
		emit_signal("interacted", object_id)
		
		queue_free()
