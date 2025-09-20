extends CanvasLayer

@onready var quest_label = $MarginContainer/QuestLabel
@onready var notification_panel = $NotificationPanel
@onready var notification_label = $NotificationPanel/MarginContainer/NotificationLabel
@onready var notification_timer = $NotificationTimer
@onready var timer_label = $TimerContainer/TimerLabel

func _ready():
	GameManager.quest_updated.connect(update_quest)
	GameManager.notification_requested.connect(show_notification)
	GameManager.timer_updated.connect(_on_timer_updated)
	GameManager.puzzle_solved.connect(_on_puzzle_finished)
	GameManager.puzzle_failed.connect(_on_puzzle_finished)
	
	quest_label.hide()
	notification_panel.hide()
	timer_label.hide()
	
	notification_timer.timeout.connect(_on_notification_timer_timeout)

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

func _on_puzzle_finished(_puzzle_id):
	timer_label.hide()
