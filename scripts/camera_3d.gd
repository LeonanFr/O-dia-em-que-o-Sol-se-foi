extends Camera3D

@export var rotation_speed: float = 5.0
var target_rotation: Vector3

func _ready():
	target_rotation = rotation

func _process(delta):
	rotation = rotation.lerp(target_rotation, delta * rotation_speed)

func _input(event):
	if event.is_action_pressed("ui_right"):
		target_rotation.y -= deg_to_rad(90)
	elif event.is_action_pressed("ui_left"):
		target_rotation.y += deg_to_rad(90)
	elif event.is_action_pressed("ui_up"):
		target_rotation.x -= deg_to_rad(90)
	elif event.is_action_pressed("ui_down"):
		target_rotation.x += deg_to_rad(90)
