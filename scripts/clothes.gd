extends InteractiveObject

@export var animation_player: AnimationPlayer

var _is_open: bool = false
var _is_anim_playing: bool = false

func _ready():
	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)

func reset():
	_is_open = false
	_is_anim_playing = false
	if animation_player:
		animation_player.play("RESET")

func interact(action: String = "") -> void:
	if action != "toggle_clothes":
		return
	
	if _is_anim_playing:
		return
	
	if animation_player:
		if _is_open:
			animation_player.play("close_clothes")
			_is_open = false
		else:
			animation_player.play("open_clothes")
			_is_open = true
		_is_anim_playing = true
	
	emit_signal("interacted", item_data.id)

func _on_animation_finished(_anim_name: String):
	_is_anim_playing = false
