extends InteractiveObject

@export var focus_marker : Marker3D

func get_focus_transform():
	return focus_marker.global_transform if focus_marker else null
