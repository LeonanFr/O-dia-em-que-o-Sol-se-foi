extends Node

signal quest_updated(text: String)
signal notification_requested(message: String)
signal interaction_denied(message: String)
signal puzzle_started(puzzle_id: String, duration: float)
signal puzzle_failed(puzzle_id: String)
signal puzzle_solved(puzzle_id: String)
signal timer_updated(time_left: float)

@export var initial_allowed_objects: Array[String] = ["tv"]
@export var find_cellphone_timer_seconds: float = 60.0

var game_over_screen_scene = preload("res://scenes/GameOverScreen.tscn")
var puzzle_timer: Timer

var _initial_allowed_objects_backup: Array[String]
var _allowed_objects: Array[String] = []
var _timer_running: bool = false
var _current_puzzle: String = ""
var _tv_puzzle_started: bool = false

func _ready() -> void:
	_initial_allowed_objects_backup = initial_allowed_objects.duplicate()
	reset()
	
	puzzle_timer = Timer.new()
	puzzle_timer.name = "PuzzleTimer"
	puzzle_timer.one_shot = true
	puzzle_timer.timeout.connect(_on_puzzle_timeout)
	add_child(puzzle_timer)
	
func _process(_delta: float) -> void:
	if _timer_running:
		emit_signal("timer_updated", puzzle_timer.time_left)
		
func reset():
	_allowed_objects = _initial_allowed_objects_backup.duplicate()
	_timer_running = false
	_current_puzzle = ""
	_tv_puzzle_started = false
	emit_quest_updated("Encontre a TV")

func request_interaction(object_id: String) -> bool:
	if object_id == "tv" and _tv_puzzle_started:
		emit_notification_requested("Não tem mais nada útil aí.")
		return false

	if object_id in _allowed_objects:
		return true
	
	var message = "Melhor não mexer nisso agora."
	if _timer_running and _current_puzzle == "find_cellphone":
		message = "Sem tempo pra isso! Cadê meu celular?!"
		
	emit_notification_requested(message)
	emit_signal("interaction_denied", message)
	return false

func notify_interacted(object_id: String) -> void:
	match object_id:
		"tv":
			if not _timer_running and _current_puzzle == "":
				_start_cellphone_puzzle()
		"cellphone":
			if _current_puzzle == "find_cellphone":
				solve_puzzle("find_cellphone")

func _start_cellphone_puzzle() -> void:
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

func solve_puzzle(puzzle_id: String) -> void:
	if _timer_running and _current_puzzle == puzzle_id:
		puzzle_timer.stop()
		_timer_running = false
		emit_quest_updated("Celular encontrado!")
		emit_signal("puzzle_solved", puzzle_id)
	_current_puzzle = ""

func _on_puzzle_timeout() -> void:
	_timer_running = false
	emit_signal("puzzle_failed", _current_puzzle)
	
	var game_over_instance = game_over_screen_scene.instantiate()
	get_tree().root.add_child(game_over_instance)
	
	get_tree().paused = true

func emit_quest_updated(text: String):
	emit_signal("quest_updated", text)

func emit_notification_requested(message: String):
	emit_signal("notification_requested", message)
