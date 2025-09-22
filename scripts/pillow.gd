extends InteractiveObject

@export var animation_player: AnimationPlayer

var is_locked: bool = false
var _is_up: bool = false

func interact(action: String = "") -> void:
	if is_locked:
		return

	emit_signal("interacted", item_data.id)

	if animation_player:
		if not _is_up:
			animation_player.play("pillow_goes_up")
			_is_up = true
		else:
			animation_player.play("pillow_goes_down")
			_is_up = false

func force_down() -> void:
	if _is_up:
		animation_player.play("pillow_goes_down")
		_is_up = false
