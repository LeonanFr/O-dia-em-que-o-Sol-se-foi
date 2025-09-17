extends StaticBody3D

@export var move_clothes_anim_player: AnimationPlayer

func _input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		move_clothes_anim_player.play("move_clothes")
