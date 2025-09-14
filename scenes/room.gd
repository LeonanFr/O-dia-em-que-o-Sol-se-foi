extends Node3D

var is_camera_focused: bool = false
var is_camera_moving: bool = false
var original_camera_transform: Transform3D
var current_focus: String = ""

@export var camera: Camera3D
@export var closet_focus: Marker3D
@export var closet_anim_player: AnimationPlayer

@export var bed_focus: Marker3D
@export var bed_anim_player: AnimationPlayer

func _unhandled_input(event: InputEvent) -> void:
	if is_camera_moving:
		return

	if is_camera_focused:
		if event.is_action_pressed("ui_down"):
			unfocus_camera()
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_viewport().get_mouse_position()
		var ray_origin = camera.project_ray_origin(mouse_pos)
		var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 1000
		
		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		var result = get_world_3d().direct_space_state.intersect_ray(query)
		
		if result.has("collider"):
			var clicked_object = result.collider
			if clicked_object.is_in_group("closet"):
				focus_on_closet()
			elif clicked_object.is_in_group("bed"):
				focus_on_bed()

func focus_on_closet() -> void:
	is_camera_moving = true
	is_camera_focused = true
	current_focus = "closet"
	camera.set_process(false)
	original_camera_transform = camera.global_transform
	
	closet_anim_player.play("open")
	
	await get_tree().process_frame
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(camera, "global_transform", closet_focus.global_transform, 1.0)
	
	await tween.finished
	is_camera_moving = false

func focus_on_bed() -> void:
	is_camera_moving = true
	is_camera_focused = true
	current_focus = "bed"
	camera.set_process(false)
	original_camera_transform = camera.global_transform
	
	bed_anim_player.play("pillow_goes_up")
	
	await get_tree().process_frame
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(camera, "global_transform", bed_focus.global_transform, 1.0)
	
	await tween.finished
	is_camera_moving = false

func unfocus_camera() -> void:
	is_camera_moving = true
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(camera, "global_transform", original_camera_transform, 1.0)
	closet_anim_player.play("close")
	
	if current_focus == "closet":
		closet_anim_player.play("close")
	elif current_focus == "bed":
		bed_anim_player.play("pillow_goes_down")
	
	await tween.finished
	
	is_camera_focused = false
	current_focus = ""
	camera.set_process(true)
	camera.target_rotation = camera.rotation
	is_camera_moving = false
