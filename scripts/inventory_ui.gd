extends CanvasLayer

@onready var slots_container = $PanelContainer/GridContainer
var password_screen_scene = preload("res://scenes/password_screen.tscn")

func _ready():
	GameManager.inventory_updated.connect(redraw_inventory)
	redraw_inventory()

func redraw_inventory():
	var inventory_items = GameManager.inventory
	var slots = slots_container.get_children()
	
	for i in range(slots.size()):
		var slot = slots[i]
		if slot.get_child_count() > 0:
			slot.get_child(0).queue_free()
			
		if i < inventory_items.size():
			var item_id = inventory_items[i]
			var item_button = Button.new()
			item_button.expand_icon = true
			item_button.icon = load("res://assets/icons/" + item_id + ".png")
			item_button.pressed.connect(_on_item_used.bind(item_id))
			slot.add_child(item_button)

func _on_item_used(item_id: String):
	match item_id:
		"cellphone":
			var password_screen = password_screen_scene.instantiate()
			password_screen.password_entered.connect(GameManager._on_password_entered)
			GameManager.puzzle_failed.connect(password_screen.queue_free)
			password_screen.tree_exited.connect(
				func():
					if GameManager.puzzle_failed.is_connected(password_screen.queue_free):
						GameManager.puzzle_failed.disconnect(password_screen.queue_free)
			)
			get_tree().root.add_child(password_screen)
