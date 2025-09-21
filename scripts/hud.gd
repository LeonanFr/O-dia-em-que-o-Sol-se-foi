extends CanvasLayer

signal ui_toggled(is_open: bool)

@onready var quest_label = $UIContainer/MarginContainer/QuestLabel
@onready var notification_panel = $NotificationPanel
@onready var notification_label = $NotificationPanel/MarginContainer/NotificationLabel
@onready var notification_timer = $NotificationTimer
@onready var timer_label = $TimerContainer/TimerLabel
@onready var inventory_slots_container = $UIContainer/MarginContainer2/PanelContainer/GridContainer
var password_screen_scene = preload("res://scenes/password_screen.tscn")

func _ready():
	GameManager.quest_updated.connect(update_quest)
	GameManager.notification_requested.connect(show_notification)
	GameManager.timer_updated.connect(_on_timer_updated)
	GameManager.puzzle_solved.connect(_on_puzzle_ended.bind(true))
	GameManager.puzzle_failed.connect(_on_puzzle_ended.bind(false))
	GameManager.inventory_updated.connect(redraw_inventory)
	
	for slot in inventory_slots_container.get_children():
			if slot is InventorySlot:
				slot.used.connect(_on_item_used)
				
	quest_label.hide()
	notification_panel.hide()
	timer_label.hide()

	notification_timer.timeout.connect(_on_notification_timer_timeout)

	redraw_inventory()

func update_quest(text: String):
	if text == "":
		quest_label.hide()
	else:
		quest_label.text = text
		quest_label.show()

func show_notification(message: String):
	notification_label.text = message
	notification_panel.show()
	notification_timer.start(3)

func _on_notification_timer_timeout():
	notification_panel.hide()

func _on_timer_updated(seconds_left: float):
	timer_label.show()
	var minutes = int(seconds_left) / 60
	var seconds = int(seconds_left) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]

func _on_puzzle_ended(puzzle_id: String, success: bool):
	timer_label.hide()
	if success:
		match puzzle_id:
			"find_cellphone":
				update_quest("")

func redraw_inventory():
	var inventory_items = GameManager.inventory
	var slots = inventory_slots_container.get_children()
	
	for i in range(slots.size()):
		var slot = slots[i]
		if i < inventory_items.size():
			slot.display_item(inventory_items[i])
		else:
			slot.clear_slot()

func _on_item_used(item_id: String):
	match item_id:
		"cellphone":
			if not GameManager.is_cellphone_unlocked():
				var password_screen = password_screen_scene.instantiate()
				password_screen.name = "PasswordScreenInstance"
				password_screen.password_entered.connect(GameManager._on_password_entered)
				GameManager.puzzle_failed.connect(password_screen.queue_free)
				emit_signal("ui_toggled", true)
				password_screen.tree_exiting.connect(func(): emit_signal("ui_toggled", false))
				get_tree().root.add_child(password_screen)
			else:
				GameManager.toggle_cellphone_light()
