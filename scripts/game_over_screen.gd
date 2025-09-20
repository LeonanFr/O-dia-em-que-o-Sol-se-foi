extends CanvasLayer

func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func _on_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()
	queue_free()
