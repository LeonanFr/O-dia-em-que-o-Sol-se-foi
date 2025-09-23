
extends InteractiveObject
class_name ExitDoor

@export var correct_code: Array[int] = [7, 5, 5, 3]

var current_code: Array[int] = [0, 0, 0, 0]
var is_solved: bool = false
var panel_is_visible: bool = false

@onready var code_panel: Node3D = $CodePanel
@onready var labels: Array[Label3D] = [
	$CodePanel/Digit1, $CodePanel/Digit2, $CodePanel/Digit3, $CodePanel/Digit4
]
@onready var click_areas: Array[Area3D] = [
	$CodePanel/ClickArea1, $CodePanel/ClickArea2, $CodePanel/ClickArea3, $CodePanel/ClickArea4
]
@export var win_screen_scene: PackedScene 

func _ready() -> void:
	for i in range(click_areas.size()):
		click_areas[i].input_event.connect(_on_digit_clicked.bind(i))
	update_display()

func _process(_delta: float) -> void:
	var flashlight_on = GameManager.is_flashlight_on
	
	if flashlight_on and not panel_is_visible:
		code_panel.show()
		panel_is_visible = true
	elif not flashlight_on and panel_is_visible:
		code_panel.hide()
		panel_is_visible = false

func _on_digit_clicked(_camera, event, _position, _normal, _shape_idx, index: int) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
		
	if is_solved:
		return
	
	current_code[index] = (current_code[index] + 1) % 10
	update_display()
	check_solution()

func update_display() -> void:
	for i in range(labels.size()):
		labels[i].text = str(current_code[i])

func check_solution() -> void:
	if current_code == correct_code:
		is_solved = true
		GameManager.emit_notification_requested("A porta destrancou!")
		
		await get_tree().create_timer(1.0).timeout
		end_game()

func end_game() -> void:
	if win_screen_scene:
		get_tree().paused = true
		var win_screen_instance = win_screen_scene.instantiate()
		get_tree().root.add_child(win_screen_instance)
	else:
		get_tree().quit()
