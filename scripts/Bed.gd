extends InteractiveObject

@export var focus_marker : Marker3D

func get_focus_transform():
	if focus_marker:
		return focus_marker.global_transform
	else:
		return null
