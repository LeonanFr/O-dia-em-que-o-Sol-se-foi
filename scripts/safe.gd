# Safe.gd
extends InteractiveObject
class_name Safe

# Sinal para travar/destravar o input do jogador
signal input_lock_requested(should_lock: bool)

# Arraste a cena SafeUI.tscn para este campo no editor
@export var safe_ui_scene: PackedScene

# Defina a senha correta para ESTE cofre no editor
@export var correct_code: Array[int] = [7, 5, 5, 3] # Ex: Lâmpada=7, Quadro=5, Relógio=53

var is_open: bool = false

func interact(_action: String = "") -> void:
	if is_open:
		GameManager.emit_notification_requested("O cofre já está aberto.")
		return
	
	if not safe_ui_scene:
		push_error("A cena da UI do cofre não foi definida no Inspector.")
		return
		
	var ui_instance = safe_ui_scene.instantiate()
	ui_instance.correct_code = correct_code
	
	ui_instance.code_correct.connect(_on_safe_unlocked)
	ui_instance.closed.connect(_on_ui_closed)
	
	get_tree().root.add_child(ui_instance)
	emit_signal("input_lock_requested", true)

func _on_safe_unlocked() -> void:
	is_open = true
	GameManager.emit_notification_requested("Você ouve um estalo alto e o cofre se abre!")
	emit_signal("input_lock_requested", false)
	

func _on_ui_closed() -> void:
	emit_signal("input_lock_requested", false)
