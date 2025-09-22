extends InteractiveObject
class_name RemoteControl

@export var body_collider: CollisionShape3D
@export var detachable_collider: CollisionShape3D
@export var detachable_mesh: MeshInstance3D
@export var battery_node: InteractiveObject

var is_cover_open := false
var is_battery_collected := false

func _ready():
	if battery_node:
		battery_node.hide()
		var battery_collider = battery_node.get_node_or_null("CollisionShape3D")
		if battery_collider:
			battery_collider.disabled = true

func on_inspection_start():
	if body_collider:
		body_collider.disabled = true
	if detachable_collider and not is_cover_open:
		detachable_collider.disabled = false

func on_inspection_stop():
	if body_collider:
		body_collider.disabled = false
	if detachable_collider:
		detachable_collider.disabled = true
	if is_cover_open and is_battery_collected:
		is_inspectable = false
		
func handle_inspection_click(raycast_result: Dictionary):
	if is_cover_open:
		return
	if not raycast_result.has("collider") or not raycast_result.has("shape"):
		return
	
	var hit_shape_node = raycast_result.collider.shape_owner_get_owner(raycast_result.shape)
	if hit_shape_node == detachable_collider:
		_open_detachable_part()
		
func _open_detachable_part():
	is_cover_open = true
	if detachable_mesh:
		detachable_mesh.hide()
	if detachable_collider:
		detachable_collider.disabled = true
	if battery_node:
		battery_node.show()
		var battery_collider = battery_node.get_node_or_null("CollisionShape3D")
		if battery_collider:
			battery_collider.disabled = false

func child_item_was_collected(child_item: InteractiveObject):
	if child_item == battery_node:
		is_battery_collected = true
		is_inspectable = false
		GameManager.add_to_inventory(child_item.item_data)
		child_item.queue_free()

func interact(_action: String = ""):
	if is_battery_collected:
		GameManager.emit_notification_requested("Já peguei o que precisava.")
