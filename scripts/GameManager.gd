extends Node

signal cellphone_light_toggled(is_on: bool)
signal cellphone_light_unlocked
signal quest_updated(text: String)
signal notification_requested(message: String)
signal interaction_denied(message: String)
signal puzzle_started(puzzle_id: String, duration: float)
signal puzzle_failed(puzzle_id: String)
signal puzzle_solved(puzzle_id: String)
signal timer_updated(time_left: float)
signal password_correct
signal inventory_updated

var is_in_darkness: bool = false
var _main_power_is_out: bool = false
var has_cellphone_light: bool = false
var has_flashlight: bool = false
var is_cellphone_light_on: bool = false
var _cellphone_is_unlocked: bool = false
var inventory: Array[String] = []

@onready var level_animator = get_tree().root.get_node("Room/LevelAnimator")
@export var initial_allowed_objects: Array[String] = ["tv"]
@export var find_cellphone_timer_seconds: float = 60.0
@export var correct_password: String = "1809"

var puzzle_timer: Timer

var game_over_screen_scene = preload("res://scenes/GameOverScreen.tscn")
var _initial_allowed_objects_backup: Array[String]
var _allowed_objects: Array[String] = []
var _timer_running: bool = false
var _current_puzzle: String = ""
var _tv_puzzle_started: bool = false

func _ready():
	_initial_allowed_objects_backup = initial_allowed_objects.duplicate()
	reset()
	puzzle_timer = Timer.new()
	puzzle_timer.name = "PuzzleTimer"
	puzzle_timer.one_shot = true
	puzzle_timer.timeout.connect(_on_puzzle_timeout)
	add_child(puzzle_timer)
	puzzle_solved.connect(_on_puzzle_solved_logic)

func _process(_delta: float):
	if _timer_running:
		emit_signal("timer_updated", puzzle_timer.time_left)

func reset():
	inventory.clear()
	emit_signal("inventory_updated")
	
	var lingering_password_screen = get_tree().root.get_node_or_null("PasswordScreenInstance")
	if lingering_password_screen:
		lingering_password_screen.queue_free()
		
	_allowed_objects = _initial_allowed_objects_backup.duplicate()
	_timer_running = false
	_current_puzzle = ""
	_tv_puzzle_started = false
	_cellphone_is_unlocked = false
	is_cellphone_light_on = false
	is_in_darkness = false
	_main_power_is_out = false
	has_cellphone_light = false
	has_flashlight = false
	emit_quest_updated("Encontre a TV")
	
func notify_interacted(object_id: String):
	match object_id:
		"tv":
			if not _timer_running and _current_puzzle == "":
				_start_cellphone_puzzle()

func _start_cellphone_puzzle():
	_tv_puzzle_started = true
	_current_puzzle = "find_cellphone"
	puzzle_timer.wait_time = find_cellphone_timer_seconds
	puzzle_timer.start()
	_timer_running = true
	_allowed_objects.clear()
	for obj in get_tree().get_nodes_in_group("interactive"):
		if obj is InteractiveObject:
			_allowed_objects.append(obj.object_id)
	emit_quest_updated("Ache uma fonte de luz")
	emit_signal("puzzle_started", _current_puzzle, find_cellphone_timer_seconds)

func solve_puzzle(puzzle_id: String):
	if _current_puzzle == puzzle_id:
		_current_puzzle = ""
		emit_signal("puzzle_solved", puzzle_id)

func _on_puzzle_solved_logic(puzzle_id: String):
	match puzzle_id:
		"find_cellphone":
			
			if _timer_running:
				puzzle_timer.stop()
				_timer_running = false
				
			_cellphone_is_unlocked = true
			emit_signal("cellphone_light_unlocked")
			emit_quest_updated("")
			
			if level_animator:
					level_animator.play("power_outage")
					
			var nodes = get_tree().get_nodes_in_group("interactive")
			
			for node in nodes:
				if node is TV:
					node.turn_off()

func on_power_cut():
	_main_power_is_out = true
	_update_darkness_state()

func is_cellphone_unlocked() -> bool:
	return _cellphone_is_unlocked

func _on_password_entered(password_attempt: String):
	if _current_puzzle == "find_cellphone":
		if password_attempt == correct_password:
			emit_signal("password_correct")
			solve_puzzle("find_cellphone")
		else:
			emit_notification_requested("Senha incorreta.")

func _on_puzzle_timeout():
	_timer_running = false
	emit_signal("puzzle_failed", _current_puzzle)
	var game_over_instance = game_over_screen_scene.instantiate()
	get_tree().root.add_child(game_over_instance)
	get_tree().paused = true


func emit_quest_updated(text: String):
	emit_signal("quest_updated", text)

func emit_notification_requested(message: String):
	emit_signal("notification_requested", message)

func request_interaction(obj: InteractiveObject) -> bool:
	if obj.object_id == "tv" and _tv_puzzle_started:
		emit_notification_requested("Não tem mais nada útil aí.")
		return false
		
	var can_see = false
	match obj.required_light:
		InteractiveObject.LightRequirement.NONE:
			can_see = true
		InteractiveObject.LightRequirement.CELLPHONE:
			if has_cellphone_light or has_flashlight:
				can_see = true
		InteractiveObject.LightRequirement.FLASHLIGHT:
			if has_flashlight:
				can_see = true
	
	if not can_see:
		emit_notification_requested("Está escuro demais para mexer nisso.")
		return false
		
	if obj.object_id in _allowed_objects:
		return true
	var message = "Melhor não mexer nisso agora."
	if _timer_running and _current_puzzle == "find_cellphone":
		message = "Sem tempo pra isso! Cadê meu celular?!"
	emit_notification_requested(message)
	emit_signal("interaction_denied", message)
	return false

func add_to_inventory(item_id: String):
	if not inventory.has(item_id):
		inventory.append(item_id)
		emit_signal("inventory_updated")

func has_in_inventory(item_id: String) -> bool:
	return inventory.has(item_id)
	
func toggle_cellphone_light():
	if not _cellphone_is_unlocked: return
	
	is_cellphone_light_on = not is_cellphone_light_on
	emit_signal("cellphone_light_toggled", is_cellphone_light_on)
	_update_darkness_state()
	
func _update_darkness_state():
	var was_in_darkness = is_in_darkness

	is_in_darkness = _main_power_is_out and not is_cellphone_light_on

	if is_in_darkness and not was_in_darkness:
		emit_notification_requested("Eu não deveria ter desligado isso.")
	elif not is_in_darkness and was_in_darkness:
		emit_notification_requested("Ufa, bem melhor.")
		
func _show_dialogue(message: String):
	emit_notification_requested(message)
