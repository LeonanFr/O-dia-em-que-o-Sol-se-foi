extends CanvasLayer

signal code_correct
signal closed

var correct_code: Array[int] = [7, 5, 5, 3]
var current_code: Array[int] = [0, 0, 0, 0]

@onready var digit_labels: Array[Label] = [
	$CenterContainer/PanelContainer/MainContainer/Column1/Digit1,
	$CenterContainer/PanelContainer/MainContainer/Column2/Digit2,
	$CenterContainer/PanelContainer/MainContainer/Column3/Digit3,
	$CenterContainer/PanelContainer/MainContainer/Column4/Digit4,
]
@onready var buttons: Array[Button] = [
	$CenterContainer/PanelContainer/MainContainer/Column1/Button1,
	$CenterContainer/PanelContainer/MainContainer/Column2/Button2,
	$CenterContainer/PanelContainer/MainContainer/Column3/Button3,
	$CenterContainer/PanelContainer/MainContainer/Column4/Button4,
]

func _ready() -> void:
	for i in range(buttons.size()):
		buttons[i].pressed.connect(_on_button_pressed.bind(i))
	update_display()

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_down"):
		emit_signal("closed")
		queue_free()

func _on_button_pressed(index: int) -> void:
	current_code[index] = (current_code[index] + 1) % 10
	update_display()
	check_solution()

func update_display() -> void:
	for i in range(digit_labels.size()):
		digit_labels[i].text = str(current_code[i])

func check_solution() -> void:
	if current_code == correct_code:
		emit_signal("code_correct")
		queue_free()
