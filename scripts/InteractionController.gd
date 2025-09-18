extends Node3D
class_name InteractionController

@export var pillow_object: Node
@export var camera_controller: CameraController
@export var debug_mode: bool = false

var is_focused: bool = false
var is_transitioning: bool = false
var focused_object: InteractiveObject = null
var original_camera_transform: Transform3D

func _ready() -> void:
	if not camera_controller:
		push_error("CameraController não foi atribuído no InteractionController!")
		get_tree().quit()
	
	original_camera_transform = camera_controller.global_transform
	GameManager.interaction_denied.connect(_on_interaction_denied)

func _unhandled_input(event: InputEvent) -> void:
	if is_transitioning or camera_controller.get_is_panning():
		return

	if is_focused:
		if event.is_action_pressed("ui_down"):
			_unfocus_current_object()
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_mouse_click(event.position)
	
	if not is_focused:
		camera_controller.handle_input(event, true)

func _handle_mouse_click(mouse_position: Vector2) -> void:
	var space_state = get_world_3d().direct_space_state
	var ray_origin = camera_controller.project_ray_origin(mouse_position)
	var ray_end = ray_origin + camera_controller.project_ray_normal(mouse_position) * 1000
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result := space_state.intersect_ray(query)

	if result.has("collider"):
		var obj = result.collider
		if obj is InteractiveObject:
			if obj.required_focus_id != "":
				if is_focused and focused_object.object_id == obj.required_focus_id:
					_trigger_interaction(obj)
			elif not is_focused:
				if debug_mode or GameManager.request_interaction(obj.object_id):
					_focus_on_object(obj)

func _trigger_interaction(obj: InteractiveObject):
	match obj.object_id:
		"closet":
			obj.interact("open")
		"clothes":
			obj.interact("move_clothes")
		"pillow":
			obj.interact()
		_:
			obj.interact()

	if not debug_mode:
		GameManager.notify_interacted(obj.object_id)

func _focus_on_object(obj: InteractiveObject) -> void:
	var target_transform = obj.get_focus_transform()
	if not target_transform:
		print("AVISO: Objeto '", obj.object_id, "' não tem um Marker3D de foco configurado.")
		return

	is_transitioning = true
	original_camera_transform = camera_controller.global_transform
	
	var tween = camera_controller.focus_on(target_transform)
	
	is_focused = true
	focused_object = obj
	
	_trigger_interaction(obj)
	
	await tween.finished
	
	is_transitioning = false

func _unfocus_current_object() -> void:
	if not is_focused:
		return
		
	is_transitioning = true
	
	if focused_object and focused_object.object_id == "closet":
		focused_object.interact("close")
		
	if focused_object and focused_object.object_id == "bed":
		if pillow_object:
			pillow_object.force_down()
	
	var tween = camera_controller.unfocus(original_camera_transform)
	await tween.finished
	
	is_focused = false
	focused_object = null
	is_transitioning = false

func _on_interaction_denied(message: String) -> void:
	print("INTERAÇÃO NEGADA: ", message)
