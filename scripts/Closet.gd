extends InteractiveObject

@export var focus_marker: Marker3D
@export var animation_player: AnimationPlayer

func get_focus_transform():
	return focus_marker.global_transform if focus_marker else null

func interact(action: String = "") -> void:
	if animation_player:
		if action == "open":
			animation_player.play("open")
		elif action == "close":
			animation_player.play("close")

	if action != "close":
		emit_signal("interacted", object_id)
