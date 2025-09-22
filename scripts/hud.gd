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
	GameManager.active_item_changed.connect(_update_all_slot_styles)
	GameManager.cellphone_light_toggled.connect(_update_all_slot_styles)

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

func _on_puzzle_ended(_puzzle_id: String, _success: bool):
	timer_label.hide()

func redraw_inventory():
	var inventory_data = GameManager.inventory
	var slots = inventory_slots_container.get_children()

	for i in range(slots.size()):
		var slot = slots[i]
		if i < inventory_data.size():
			slot.display_item(inventory_data[i])
		else:
			slot.clear_slot()

	_update_all_slot_styles()

func _on_item_used(slot: InventorySlot):
	if not slot.slot_data: 
		return
	
	var item_data = slot.slot_data.item
	if not item_data: 
		return
	
	match item_data.type:
		ItemData.ItemType.ACTIVATABLE:
			GameManager.set_active_item(item_data)
		ItemData.ItemType.DIRECT_USE:
			GameManager.use_item_directly(item_data)
	redraw_inventory()


func _update_all_slot_styles(_payload = null):
	var active_tool_id = GameManager.active_tool.id if GameManager.active_tool else ""
	
	for slot in inventory_slots_container.get_children():
		if not (slot is InventorySlot and slot.slot_data and slot.slot_data.item):
			continue
			
		var item_data = slot.slot_data.item
		var is_active = false
		var current_item_id = item_data.id
		
		if current_item_id == active_tool_id:
			is_active = true
		elif item_data.type == ItemData.ItemType.DIRECT_USE:
			var direct_use_is_active = GameManager.is_direct_use_item_active(current_item_id)
			if direct_use_is_active:
				is_active = true
		
		var new_stylebox = slot.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if is_active:
			new_stylebox.bg_color = Color(0.2, 0.3, 0.5, 0.7)
		else:
			new_stylebox.bg_color = Color("#3d3d3d")
		slot.add_theme_stylebox_override("panel", new_stylebox)
