extends Node3D

@export var frames: Array[PictureFrame]

@export var solution: Dictionary = {
	"ALPHA": 0.0,
	"BETA": 90.0,
	"SIGMA": 180.0,
	"DELTA": 270.0
}

@export var frame_to_reveal_on: PictureFrame
@export var number_to_reveal: int = 5

var is_solved: bool = false


func _ready() -> void:
	for frame in frames:
		if frame:
			frame.rotated.connect(_on_frame_rotated)

func _on_frame_rotated(_frame_symbol: String, _current_rotation: float) -> void:
	check_solution()

func check_solution() -> void:
	if is_solved:
		return

	for frame in frames:
		if not frame or not solution.has(frame.symbol):
			push_error("Configuração de quadro ou solução incorreta para o símbolo: " + frame.symbol)
			return
			
		var correct_rotation = solution[frame.symbol]
		if not is_equal_approx(frame.current_rotation_degrees, correct_rotation):
			return

	is_solved = true
	GameManager.emit_notification_requested("Você ouve um clique vindo de um dos quadros...")
	
	if frame_to_reveal_on:
		frame_to_reveal_on.reveal_number(number_to_reveal)
		
	for frame in frames:
		if frame:
			frame.disable_interaction()
