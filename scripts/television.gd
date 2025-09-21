extends InteractiveObject
class_name TV

signal input_lock_requested(should_lock: bool)

@export var focus_marker: Marker3D
@export var animation_player: AnimationPlayer
@export var label_text: Label3D
@export var screen_black: MeshInstance3D
@export var screen_video: MeshInstance3D

var has_been_activated: bool = false

func get_focus_transform():
	return focus_marker.global_transform if focus_marker else null

func _ready():
	GameManager.puzzle_failed.connect(_on_puzzle_failed)
	
	label_text.hide()
	screen_video.hide()
	screen_black.show()

func interact(action: String = "") -> void:
	if has_been_activated:
		return

	if animation_player and action == "turn_on":
		animation_player.play("play_intro")

func turn_off():
	if screen_video:
		screen_video.hide()
	if screen_black:
		screen_black.show()

func _on_intro_started():
	has_been_activated = true

func _on_intro_finished():
	emit_signal("interacted", object_id)

func _lock_input():
	emit_signal("input_lock_requested", true)

func _unlock_input():
	emit_signal("input_lock_requested", false)

func _on_puzzle_failed(puzzle_id: String):
	if puzzle_id == "find_cellphone":
		label_text.hide()
		screen_video.hide()
		screen_black.show()
