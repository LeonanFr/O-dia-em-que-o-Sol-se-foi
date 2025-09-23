extends InteractiveObject
class_name ColorPuzzle

@export var button_scene: PackedScene
@export var button_positions: Array[Vector3]
@export var correct_sequence: Array[Color]
@export var target_to_unlock: Node
@export var focus_marker: Marker3D

var buttons: Array[ButtonPress] = []
var is_solved: bool = false

func _ready():
	if not is_solved:
		_instantiate_buttons()
		
func _instantiate_buttons():
	if not button_scene:
		push_error("ButtonPress scene não foi atribuída!")
		return
	
	for pos in button_positions:
		var new_button = button_scene.instantiate() as ButtonPress
		add_child(new_button)
		new_button.position = pos
		new_button.button_pressed.connect(check_solution)
		buttons.append(new_button)
	_set_buttons_enabled(false)
	
func _set_buttons_enabled(enabled: bool):
	for button in buttons:
		button._set_interaction_enabled(enabled)
		
func get_focus_transform():
	if focus_marker:
		return focus_marker.global_transform
	else:
		return null
	
func check_solution(_color: Color):
	if is_solved:
		return

	var current_colors: Array[Color] = []
	for button in buttons:
		current_colors.append(button.get_current_color())

	if current_colors == correct_sequence:
		is_solved = true
		GameManager.emit_notification_requested("Você ouve um clique vindo da gaveta.")
		disable_all_buttons()
		_unlock_target()

func disable_all_buttons():
	for button in buttons:
		button.disable_button()

func _unlock_target():
	print(target_to_unlock)
	print(target_to_unlock.has_method("unlock_drawer"))
	if target_to_unlock and target_to_unlock.has_method("unlock_drawer"):
		target_to_unlock.unlock_drawer()
	else:
		push_error("O alvo para desbloqueio não foi definido ou não tem o método 'unlock_drawer'.")
