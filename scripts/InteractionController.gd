extends Node3D
class_name InteractionController

@export var main_light: OmniLight3D
@export var cellphone_light: SpotLight3D
@export var camera_controller: CameraController
@export var pillow_object: Node 
@export var debug_mode: bool = false
@export var inspection_tween_duration: float = 0.4

var is_focused: bool = false
var is_transitioning: bool = false
var input_locked: bool = false
var focused_object: InteractiveObject = null
var original_camera_transform: Transform3D

var is_inspecting: bool = false
var inspected_object: InteractiveObject = null
var _inspected_object_original_parent: Node = null
var _inspected_object_original_transform: Transform3D

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
	if is_inspecting:
		if event.is_action_pressed("ui_down"):
			_stop_inspection()
			return
		if event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_LEFT:
			if inspected_object:
				inspected_object.rotate_y(deg_to_rad(-event.relative.x * 0.4))
				inspected_object.rotate_x(deg_to_rad(-event.relative.y * 0.4))
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_handle_mouse_click(event.position)
		return

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
		
		if not (obj is InteractiveObject):
			print("  -> FIM: Objeto não é um InteractiveObject (", obj, "). Ignorando.")
			return
		if is_inspecting:
			if obj == inspected_object or inspected_object.is_ancestor_of(obj):
				if obj == inspected_object:
					inspected_object.handle_inspection_click(result)
				elif obj is InteractiveObject:
					inspected_object.child_item_was_collected(obj)
			return
		
		if obj is InteractiveObject:
			if GameManager.active_tool:
				obj.use_tool(GameManager.active_tool)
				return
			
			if is_focused:
				if obj.required_focus_id != "" and focused_object.item_data and focused_object.item_data.id == obj.required_focus_id:
					_trigger_interaction(obj)
				elif focused_object.is_ancestor_of(obj):
					if obj.is_inspectable:
						_start_inspection(obj)
					else:
						_trigger_interaction(obj)
			else:
				if not debug_mode and not GameManager.request_interaction(obj):
					return

				if obj.is_inspectable:
					_start_inspection(obj)
				elif obj.get_focus_transform():
					_focus_on_object(obj)
				else:
					_trigger_interaction(obj)

			
func _trigger_interaction(obj: InteractiveObject):
	if not obj.item_data:
		obj.interact()
		return

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
	if not target_transform:
		_trigger_interaction(obj) 
		return
		
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

func _start_inspection(obj: InteractiveObject):
	if camera_controller.is_busy() or is_transitioning: return

	is_inspecting = true
	input_locked = true
	is_transitioning = true
	
	inspected_object = obj
	_inspected_object_original_parent = obj.get_parent()
	_inspected_object_original_transform = obj.global_transform
	
	var inspection_point = camera_controller.get_node("InspectionPoint")
	obj.on_inspection_start()
	obj.reparent(inspection_point)
	obj.scale = _inspected_object_original_transform.basis.get_scale()
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(obj, "position", Vector3.ZERO, inspection_tween_duration)
	tween.tween_property(obj, "rotation", Vector3.ZERO, inspection_tween_duration)
	await tween.finished
	
	is_transitioning = false


func _stop_inspection():
	if not is_inspecting or not is_instance_valid(inspected_object): return

	is_transitioning = true
	
	inspected_object.on_inspection_stop()
	inspected_object.reparent(_inspected_object_original_parent)
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(inspected_object, "global_transform", _inspected_object_original_transform, inspection_tween_duration)
	await tween.finished
	
	is_inspecting = false
	input_locked = false
	inspected_object = null
	_inspected_object_original_parent = null
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
