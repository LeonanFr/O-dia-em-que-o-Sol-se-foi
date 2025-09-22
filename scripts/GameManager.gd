extends Node

signal active_item_changed(item_id: String)
signal cellphone_light_toggled(is_on: bool)
signal flashlight_toggled(is_on: bool)
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

enum GameState { START, FIND_CELLPHONE_PUZZLE, ROOM_EXPLORATION }
var current_state: GameState = GameState.START
var active_tool: ItemData = null
var active_light_source: ItemData = null
var is_in_darkness: bool = false
var _main_power_is_out: bool = false
var has_cellphone_light: bool = false
var has_flashlight: bool = false
var is_cellphone_light_on: bool = false
var is_flashlight_on: bool = false
var _cellphone_is_unlocked: bool = false
var inventory: Array[InventorySlotData] = []

@onready var level_animator = get_tree().root.get_node("Room/LevelAnimator")
@export var find_cellphone_timer_seconds: float = 60.0
@export var correct_password: String = "1809"

var puzzle_timer: Timer
var game_over_screen_scene = preload("res://scenes/GameOverScreen.tscn")
var _timer_running: bool = false
var _current_puzzle: String = ""
var _tv_puzzle_started: bool = false

func _ready():
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
		
	_timer_running = false
	_current_puzzle = ""
	active_tool = null
	active_light_source = null
	emit_signal("active_item_changed", "")
	_tv_puzzle_started = false
	_cellphone_is_unlocked = false
	is_cellphone_light_on = false
	is_in_darkness = false
	_main_power_is_out = false
	has_cellphone_light = false
	has_flashlight = false
	emit_quest_updated("Encontre a TV")

func can_combine(first: ItemData, second: ItemData) -> bool:
	if first.id == "flashlight" and second.id == "battery":
		return true
	if first.id == "battery" and second.id == "flashlight":
		return true
	return false
	
func set_active_item(item_data: ItemData):
	var previous_active_tool = active_tool

	if active_tool == item_data:
		active_tool = null
		emit_signal("active_item_changed", "")
		return

	if previous_active_tool and can_combine(previous_active_tool, item_data):
		var flashlight_item = previous_active_tool if previous_active_tool.id == "flashlight" else item_data
		var battery_item = previous_active_tool if previous_active_tool.id == "battery" else item_data

		if flashlight_item and battery_item:
			remove_from_inventory(battery_item.id)
			if active_tool == battery_item:
				active_tool = null
				emit_signal("active_item_changed", "")

			if flashlight_item.add_battery():
				remove_from_inventory(flashlight_item.id)
				has_flashlight = true

		return

	active_tool = item_data

	var message = get_item_feedback_message(item_data)
	if message != "":
		emit_notification_requested(message)

	emit_signal("active_item_changed", item_data.id)

	
func get_item_feedback_message(item_data: ItemData) -> String:
	if item_data.display_name == "":
		return ""
		
	match item_data.id:
		"cellphone":
			return ""
	
	return item_data.display_name.capitalize()

func use_item_directly(item_data: ItemData):
	match item_data.id:
		"cellphone":
			if not is_cellphone_unlocked():
				var password_screen_scene = load("res://scenes/password_screen.tscn")
				var password_screen = password_screen_scene.instantiate()
				password_screen.name = "PasswordScreenInstance"
				password_screen.password_entered.connect(_on_password_entered)
				get_tree().root.add_child(password_screen)
			else:
				toggle_cellphone_light()
		"charged_flashlight":
			toggle_flashlight()
	
func notify_interacted(object_id: String):
	match object_id:
		"tv":
			if current_state == GameState.START:
				current_state = GameState.FIND_CELLPHONE_PUZZLE
				
				var tv_node = get_tree().get_root().get_node("Room/InteractiveFurniture/Television")
				
				tv_node.connect("interacted", Callable(self, "_on_tv_intro_finished"))
				
				tv_node.interact("turn_on")

func _on_tv_intro_finished(_tv_id: String):
	emit_quest_updated("Ache uma fonte de luz")
	_start_cellphone_puzzle()
	
	var tv_node = get_tree().get_root().get_node("Room/InteractiveFurniture/Television")
	tv_node.disconnect("interacted", Callable(self, "_on_tv_intro_finished"))


func _start_cellphone_puzzle():
	_tv_puzzle_started = true
	_current_puzzle = "find_cellphone"
	puzzle_timer.wait_time = find_cellphone_timer_seconds
	puzzle_timer.start()
	_timer_running = true
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
	if not obj.item_data:
		return false

	if current_state == GameState.START:
		if obj.item_data.id != "tv":
			emit_notification_requested("Não tenho tempo para isso agora.")
			return false
		else:
			notify_interacted("tv")
			current_state = GameState.FIND_CELLPHONE_PUZZLE
			return true

	if obj.item_data.id == "tv":
		emit_notification_requested("Não tem mais nada para ver.")
		return false

	if obj.required_focus_id != "":
		var current_focus_id = active_tool.id if active_tool else ""
		if current_focus_id != obj.required_focus_id:
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
		var msg = "Está escuro demais para mexer nisso."
		emit_notification_requested(msg)
		emit_signal("interaction_denied", msg)
		return false

	return true

func add_to_inventory(new_item_data: ItemData):
	if new_item_data.id == "cellphone" and has_flashlight:
		print("Celular bloqueado porque a lanterna está ativa")
		return
		
		
		
	for slot_data in inventory:
		if slot_data.item.id == new_item_data.id:
			slot_data.quantity += 1
			emit_signal("inventory_updated")
			return

	var new_slot_data = InventorySlotData.new(new_item_data, 1)
	inventory.append(new_slot_data)
	emit_signal("inventory_updated")

func remove_from_inventory(item_id_to_remove: String):
	for i in range(inventory.size() - 1, -1, -1):
		var slot_data = inventory[i]
		if slot_data.item.id == item_id_to_remove:
			slot_data.quantity -= 1
			if slot_data.quantity <= 0:
				inventory.remove_at(i)
			emit_signal("inventory_updated")
			return

func has_in_inventory(item_id: String) -> bool:
	for item in inventory:
		if item.id == item_id:
			return true
	return false
	
func toggle_cellphone_light():
	if not _cellphone_is_unlocked: return
	
	is_cellphone_light_on = not is_cellphone_light_on
	emit_signal("cellphone_light_toggled", is_cellphone_light_on)
	_update_darkness_state()
	
func toggle_flashlight():
	if not has_flashlight:
		return
	is_flashlight_on = not is_flashlight_on
	active_light_source = preload("res://items/charged_flashlight.tres") if is_flashlight_on else null
	_update_darkness_state()
	emit_signal("flashlight_toggled", is_flashlight_on)
	
func is_direct_use_item_active(item_id: String) -> bool:
	match item_id:
		"cellphone":
			return is_cellphone_light_on
		"charged_flashlight":
			return is_flashlight_on
	return false
	
func _update_darkness_state():
	var was_in_darkness = is_in_darkness
	is_in_darkness = _main_power_is_out and not (is_cellphone_light_on or is_flashlight_on)
	if is_in_darkness and not was_in_darkness:
		emit_notification_requested("Está escuro demais.")
	elif not is_in_darkness and was_in_darkness:
		emit_notification_requested("Ufa, bem melhor.")

func _show_dialogue(message: String):
	emit_notification_requested(message)
