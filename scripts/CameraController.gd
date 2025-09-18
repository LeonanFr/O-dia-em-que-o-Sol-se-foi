extends Camera3D
class_name CameraController

@export var rotation_duration: float = 0.4
@export var rotate_angle_deg: float = 90.0

var target_rotation: Vector3
var is_moving_focus: bool = false
var is_panning: bool = false

func _ready():
	target_rotation = rotation

func handle_input(event: InputEvent, allow_rotation: bool):
	if not allow_rotation or is_moving_focus or is_panning:
		return
	if event.is_action_pressed("ui_left"):
		rotate_left()
	elif event.is_action_pressed("ui_right"):
		rotate_right()

func rotate_left():
	if is_panning:
		return
	is_panning = true
	var visual_target = rotation
	visual_target.y += deg_to_rad(rotate_angle_deg)
	target_rotation.y += deg_to_rad(rotate_angle_deg)
	var tween = create_tween().set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(self, "rotation", visual_target, rotation_duration)
	await tween.finished
	target_rotation.y = wrapf(target_rotation.y, 0, TAU)
	rotation = target_rotation
	is_panning = false

func rotate_right():
	if is_panning:
		return
	is_panning = true
	var visual_target = rotation
	visual_target.y -= deg_to_rad(rotate_angle_deg)
	target_rotation.y -= deg_to_rad(rotate_angle_deg)
	var tween = create_tween().set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(self, "rotation", visual_target, rotation_duration)
	await tween.finished
	target_rotation.y = wrapf(target_rotation.y, 0, TAU)
	rotation = target_rotation
	is_panning = false

func focus_on(transform: Transform3D) -> Tween:
	is_moving_focus = true
	var tween = create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "global_transform", transform, 1.0)
	tween.finished.connect(_on_focus_tween_finished) # Conecta o sinal 'finished'
	return tween

func unfocus(transform: Transform3D) -> Tween:
	is_moving_focus = true
	var tween = create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "global_transform", transform, 1.0)
	tween.finished.connect(_on_focus_tween_finished) # Conecta o sinal 'finished'
	return tween

func _on_focus_tween_finished():
	# Esta função é chamada automaticamente quando qualquer tween de foco/desfoco termina
	is_moving_focus = false

func is_moving() -> bool:
	return is_moving_focus

func get_is_panning() -> bool:
	return is_panning
