extends InteractiveObject

@export var item_id: int = 1

func interact(action: String = "") -> void:
	var closet_manager = get_tree().get_first_node_in_group("closet_manager")
	if closet_manager:
		closet_manager.on_item_clicked(self)
