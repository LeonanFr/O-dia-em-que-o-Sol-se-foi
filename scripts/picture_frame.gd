extends InteractiveObject
class_name PictureFrame

signal rotated(frame_symbol, current_rotation_degrees)

@export var symbol: String = "ALPHA"

var current_rotation_degrees: float = 0.0
var rotation_step: float = 45.0
var interaction_enabled: bool = true

@export var symbol_label: Label3D
@onready var number_label: Label3D = $NumberLabel


func _ready() -> void:
	symbol_label.text = get_symbol_character(symbol)
	number_label.hide()
	
func interact(_action: String = "") -> void:
	if not interaction_enabled:
		GameManager.emit_notification_requested("Acho que isso já está no lugar certo.")
		return
	
	current_rotation_degrees = wrapf(current_rotation_degrees + rotation_step, 0, 360)
	
	var target_rotation_rad = Vector3(
		self.rotation.x,
		self.rotation.y,
		deg_to_rad(current_rotation_degrees)
	)
	
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", target_rotation_rad, 0.4)
	
	emit_signal("rotated", symbol, current_rotation_degrees)


func reveal_number(number: int) -> void:
	number_label.text = str(number)
	number_label.show()

func disable_interaction() -> void:
	interaction_enabled = false

func get_symbol_character(symbol_id: String) -> String:
	match symbol_id.to_upper():
		"ALPHA": return "α"
		"BETA": return "β"
		"GAMMA": return "Γ"
		"DELTA": return "Δ"
		"SIGMA": return "Σ"
		_: return "?"
