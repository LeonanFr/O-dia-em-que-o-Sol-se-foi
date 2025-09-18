extends InteractiveObject

@export var animation_player: AnimationPlayer

var _has_been_moved: bool = false

func interact(action: String = "") -> void:
	if _has_been_moved:
		return

	emit_signal("interacted", object_id)
	
	if animation_player and action == "move_clothes":
		animation_player.play("move_clothes")
		_has_been_moved = true
