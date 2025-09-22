extends Node3D
class_name InteractionController

@export var main_light: OmniLight3D
@export var cellphone_light: SpotLight3D
@export var camera_controller: CameraController
@export var pillow_object: Node 
@export var debug_mode: bool = false

var is_focused: bool = false
var is_transitioning: bool = false
var input_locked: bool = false
var focused_object: InteractiveObject = null
var original_camera_transform: Transform3D

func _ready():
	GameManager.reset()
	GameManager.cellphone_light_toggled.connect(_on_cellphone_light_toggled)
	if not camera_controller:
		push_error("CameraController não foi atribuído no InteractionController!")
		get_tree().quit()
	
	original_camera_transform = camera_controller.global_transform
	GameManager.interaction_denied.connect(_on_interaction_denied)
	
	var hud = get_tree().root.get_node("Hud")
	if hud and hud.has_signal("ui_toggled"):
		hud.ui_toggled.connect(lock_input)
			
	var interactive_objects = get_tree().get_nodes_in_group("interactive")
	for obj in interactive_objects:
		if obj.has_signal("interacted"):
			obj.interacted.connect(GameManager.notify_interacted)
		if obj is TV:
			obj.input_lock_requested.connect(lock_input)

func _unhandled_input(event: InputEvent):
	if GameManager.is_in_darkness:
		if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right") or \
		(event is InputEventMouseButton and event.is_pressed()):
			GameManager.emit_notification_requested("Não consigo ver nada!")
		return
	if input_locked or is_transitioning or camera_controller.is_busy():
		return
	if is_focused:
		if event.is_action_pressed("ui_down"):
			_unfocus_current_object()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_mouse_click(event.position)
	if not is_focused:
		camera_controller.handle_input(event, true)

func _handle_mouse_click(mouse_position: Vector2):
	var space_state = get_world_3d().direct_space_state
	var ray_origin = camera_controller.project_ray_origin(mouse_position)
	var ray_end = ray_origin + camera_controller.project_ray_normal(mouse_position) * 1000
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result := space_state.intersect_ray(query)

	if result.has("collider"):
		var obj = result.collider
		if obj is InteractiveObject:
			if GameManager.active_tool:
				obj.use_tool(GameManager.active_tool)
				return
			
			if not obj.item_data: return

			if obj.required_focus_id != "":
				if is_focused and focused_object.item_data and focused_object.item_data.id == obj.required_focus_id:
					_trigger_interaction(obj)
			elif is_focused:
				if GameManager.request_interaction(obj):
					_trigger_interaction(obj)
			elif not is_focused:
				if debug_mode or GameManager.request_interaction(obj):
					_focus_on_object(obj)

func _trigger_interaction(obj: InteractiveObject):
	if not obj.item_data: return

	if obj.item_data.is_collectible:
		GameManager.add_to_inventory(obj.item_data)
		obj.queue_free()
		return
		
	match obj.item_data.id:
		"tv":
			obj.interact("turn_on")
		"desk":
			obj.interact()
		"closet":
			obj.interact("open")
		"clothes":
			obj.interact("move_clothes")
		"pillow":
			obj.interact()
		_:
			obj.interact()

func _focus_on_object(obj: InteractiveObject):
	var target_transform = obj.get_focus_transform()
		
	if obj.item_data and obj.item_data.id == "tv":
		GameManager.emit_quest_updated("")
	
	is_transitioning = true
	original_camera_transform = camera_controller.global_transform
	var tween = camera_controller.focus_on(target_transform)
	is_focused = true
	focused_object = obj
	_trigger_interaction(obj)
	await tween.finished
	if obj.is_container and obj.collision_shape:
		obj.collision_shape.disabled = true
	is_transitioning = false

func _unfocus_current_object():
	if not is_focused: return

	if focused_object and focused_object.is_container and focused_object.collision_shape:
		focused_object.collision_shape.disabled = false
		
	is_transitioning = true
	
	if focused_object and focused_object.item_data:
		match focused_object.item_data.id:
			"closet":
				focused_object.interact("close")
			"desk":
				focused_object.close_all_drawers()
			"bed":
				if pillow_object:
					pillow_object.force_down()
	
	var tween = camera_controller.unfocus(original_camera_transform)
	await tween.finished
	is_focused = false
	focused_object = null
	is_transitioning = false

func _on_interaction_denied():
	pass

func lock_input(should_lock: bool):
	input_locked = should_lock
	
func turn_off_emissives():
	var emissive_objects = get_tree().get_nodes_in_group("emissive_objects")
	for obj in emissive_objects:
		if obj is MeshInstance3D:
			var mat = obj.get_active_material(0)
			if mat:
				mat.emission_enabled = false

func _on_cellphone_light_toggled(is_on: bool):
	if cellphone_light:
		cellphone_light.visible = is_on

func _on_power_cut():
	GameManager.on_power_cut()
	GameManager._show_dialogue("Droga! Fiquei sem energia. Como vou enxergar algo?")

func _on_start_power_cut():
	if is_focused and focused_object:
		_unfocus_current_object()
	GameManager._show_dialogue("Mas... O que foi isso?")
