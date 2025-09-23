extends InteractiveObject
class_name Dresser

@export var locked_drawer: Node = null
@export var interactive_drawers: Array[Node]
@export var drawer_move_distance: float = 22
@export var drawer_anim_duration: float = 0.6
@export var focus_marker: Marker3D

var drawer_data := {}

func _ready():
	for drawer in interactive_drawers:
		if drawer:
			var is_this_drawer_locked = (drawer == locked_drawer)
			drawer_data[drawer] = {
				"is_open": false,
				"initial_pos": drawer.position,
				"is_locked": is_this_drawer_locked
			}
			var area = drawer.get_node_or_null("Area3D")
			if area:
				area.input_event.connect(_on_drawer_clicked.bind(drawer))

func get_focus_transform():
	if focus_marker:
		return focus_marker.global_transform
	return null

func _on_drawer_clicked(_camera, event, _position, _normal, _shape_idx, drawer_node):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var data = drawer_data.get(drawer_node)
		if not data: return
		
		if data.is_locked:
			GameManager.emit_notification_requested("Está trancada.")
		else:
			animate_drawer(drawer_node)

func animate_drawer(drawer_node, force_state: String = "toggle"):
	var data = drawer_data.get(drawer_node)
	if data == null:
		return

	var is_open = data.get("is_open", false)
	var should_open: bool

	match force_state:
		"toggle": should_open = not is_open
		"close": should_open = false
		"open": should_open = true

	if should_open == is_open:
		return

	data.is_open = should_open

	var target_position = drawer_node.position
	if should_open:
		target_position.z = data.initial_pos.z - drawer_move_distance
	else:
		target_position.z = data.initial_pos.z

	if drawer_node.has_meta("active_tween"):
		var old_tween = drawer_node.get_meta("active_tween")
		if old_tween:
			old_tween.kill()
			drawer_node.remove_meta("active_tween")

	var tween = create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(drawer_node, "position", target_position, drawer_anim_duration)
	tween.finished.connect(func():
		drawer_node.remove_meta("active_tween")
	)
	drawer_node.set_meta("active_tween", tween)
	
func unlock_drawer():
	if locked_drawer and drawer_data.has(locked_drawer):
		var data = drawer_data[locked_drawer]
		data.is_locked = false
		print("Gaveta desbloqueada!")
	else:
		push_warning("Tentativa de desbloquear uma gaveta que não está configurada como 'locked_drawer'.")
		
func close_all_drawers():
	for drawer in drawer_data:
		var data = drawer_data[drawer]
		if data.is_open:
			animate_drawer(drawer, "close")

func interact(_action: String = "") -> void:
	emit_signal("interacted", item_data.id)
