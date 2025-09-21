extends CanvasLayer

signal password_entered(password_attempt: String)

@export var display_container: HBoxContainer
@export var number_pad: VBoxContainer 
@export var clear_button: Button
@export var cancel_button: Button

var current_input: String = ""
var password_length: int = 4

func _ready():
	for row in number_pad.get_children():
		for button in row.get_children():
			if button is Button:
				button.pressed.connect(_on_number_button_pressed.bind(button.text))
	clear_button.pressed.connect(_on_clear_button_pressed)
	cancel_button.pressed.connect(queue_free)
	update_display()

func _on_number_button_pressed(number: String):
	if current_input.length() < password_length:
		current_input += number
		update_display()
	if current_input.length() == password_length:
		submit_password()

func _on_clear_button_pressed():
	current_input = ""
	update_display()

func submit_password():
	emit_signal("password_entered", current_input)
	queue_free()

func update_display():
	for i in range(display_container.get_child_count()):
		var dot = display_container.get_child(i) as Panel
		if dot:
			dot.modulate = Color.WHITE if i < current_input.length() else Color(0.2, 0.2, 0.2, 1)
