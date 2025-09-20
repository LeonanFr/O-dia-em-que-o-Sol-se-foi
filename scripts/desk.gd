extends InteractiveObject
class_name Desk

@export var interactive_drawers: Array[Node]
@export var drawer_move_distance: float = 0.5
@export var drawer_anim_duration: float = 0.6
@export var focus_marker: Marker3D

var drawer_states := {}

func _ready():
	for drawer in interactive_drawers:
		if drawer:
			drawer_states[drawer] = false
			var area = drawer.get_node_or_null("Area3D")
			if area:
				area.input_event.connect(_on_drawer_clicked.bind(drawer))

func get_focus_transform():
	if focus_marker:
		return focus_marker.global_transform
	return null

func _on_drawer_clicked(camera, event, position, normal, shape_idx, drawer_node):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		animate_drawer(drawer_node)

func animate_drawer(drawer_node):
	if drawer_node.has_meta("is_moving") and drawer_node.get_meta("is_moving"):
		return
	
	drawer_node.set_meta("is_moving", true)

	var is_open = drawer_states.get(drawer_node, false)
	var initial_position = drawer_node.position
	var target_position = initial_position

	if not is_open:
		target_position.x -= drawer_move_distance
	else:
		target_position.x += drawer_move_distance
	
	var tween = create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(drawer_node, "position", target_position, drawer_anim_duration)
	
	await tween.finished
	
	drawer_states[drawer_node] = not is_open
	drawer_node.remove_meta("is_moving")

func interact(action: String = "") -> void:
	emit_signal("interacted", object_id)
