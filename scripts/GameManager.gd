extends Node

signal interaction_denied(message: String)
signal puzzle_started(puzzle_id: String, duration: float)
signal puzzle_failed(puzzle_id: String)
signal puzzle_solved(puzzle_id: String)
signal timer_updated(time_left: float)

@export var initial_allowed_objects: Array[String] = ["tv"]
@export var find_flashlight_timer_seconds: float = 60.0

var puzzle_timer: Timer

var _allowed_objects: Array[String] = []
var _timer_running: bool = false
var _current_puzzle: String = ""

func _ready() -> void:
	_allowed_objects = initial_allowed_objects.duplicate()
	
	puzzle_timer = Timer.new()
	puzzle_timer.name = "PuzzleTimer"
	puzzle_timer.one_shot = true
	puzzle_timer.timeout.connect(_on_puzzle_timeout)
	add_child(puzzle_timer)

func _process(_delta: float) -> void:
	if _timer_running:
		emit_signal("timer_updated", puzzle_timer.time_left)

func request_interaction(object_id: String) -> bool:
	if object_id in _allowed_objects:
		return true
	
	if _timer_running and _current_puzzle == "find_flashlight":
		emit_signal("interaction_denied", "Não tenho tempo para isso, preciso achar uma luz!")
		return false
		
	emit_signal("interaction_denied", "Eu não deveria olhar isso agora.")
	return false

func notify_interacted(object_id: String) -> void:
	match object_id:
		"tv":
			if not _timer_running and _current_puzzle == "":
				_start_flashlight_puzzle()
		"lantern":
			if _current_puzzle == "find_flashlight":
				solve_puzzle("find_flashlight")

func _start_flashlight_puzzle() -> void:
	_current_puzzle = "find_flashlight"
	puzzle_timer.wait_time = find_flashlight_timer_seconds
	puzzle_timer.start()
	_timer_running = true
	
	_allowed_objects.clear()
	for obj in get_tree().get_nodes_in_group("interactive"):
		if obj is InteractiveObject:
			_allowed_objects.append(obj.object_id)
	
	emit_signal("puzzle_started", _current_puzzle, find_flashlight_timer_seconds)
	print("PUZZLE INICIADO: Encontre a lanterna!")

func solve_puzzle(puzzle_id: String) -> void:
	if _timer_running and _current_puzzle == puzzle_id:
		puzzle_timer.stop()
		_timer_running = false
		emit_signal("puzzle_solved", puzzle_id)
		print("PUZZLE RESOLVIDO: ", puzzle_id)
	
	_current_puzzle = ""

func _on_puzzle_timeout() -> void:
	_timer_running = false
	emit_signal("puzzle_failed", _current_puzzle)
	get_tree().reload_current_scene()
