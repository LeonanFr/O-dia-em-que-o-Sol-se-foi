extends InteractiveObject

@export var focus_marker: Marker3D
@export var animation_player: AnimationPlayer

@export var slots: Array[Node3D] = []
@export var puzzle_objects: Array[Node3D] = []
@export var correct_order: Array[int] = [5, 2, 0, 4, 1, 3]

var selected: Node3D = null
var labels: Array[Label3D] = []

func _ready() -> void:
	animation_player.play("RESET")
	add_to_group("closet_manager")
	
	slots = [
		$Slot1, $Slot2, $Slot3,
		$Slot4, $Slot5, $Slot6
	]

	puzzle_objects = [
		$bag, #0
		$shoes, #1
		$frog, #2
		$camisas, #3
		$jeans, #4
		$towel #5
	]
	#marrom, verde, azul, azul, vermelho, preto | towel, frog, bag, jeans, shoes, camisas

	# Posiciona os objetos nos slots
	for i in range(min(puzzle_objects.size(), slots.size())):
		place_object_in_slot(puzzle_objects[i], slots[i])

	labels = [
		get_node_or_null("Label1"),
		get_node_or_null("Label2"),
		get_node_or_null("Label3"),
		get_node_or_null("Label4"),
	]
	for label in labels:
		if label:
			label.hide()

func get_focus_transform() -> Transform3D:
	return focus_marker.global_transform if focus_marker else null

func interact(action: String = "") -> void:
	if animation_player:
		if action == "open":
			animation_player.play("open")
		elif action == "close":
			animation_player.play("close")

func on_item_clicked(obj: Node3D) -> void:
	if selected == null:
		selected = obj
		print("Selecionado:", obj.name)
	else:
		print("Trocando:", selected.name, "<->", obj.name)
		swap_objects(selected, obj)
		selected = null
		check_solution()

func swap_objects(obj1: Node3D, obj2: Node3D) -> void:
	var i1 = puzzle_objects.find(obj1)
	var i2 = puzzle_objects.find(obj2)
	if i1 == -1 or i2 == -1:
		return

	puzzle_objects[i1] = obj2
	puzzle_objects[i2] = obj1

	place_object_in_slot(obj1, slots[i2])
	place_object_in_slot(obj2, slots[i1])

func place_object_in_slot(obj: Node3D, slot: Node3D) -> void:
	obj.global_position = slot.global_position
	obj.global_rotation = slot.global_rotation

func check_solution() -> void:
	var current: Array[int] = []
	for obj in puzzle_objects:
		if obj.has_method("get"):
			current.append(obj.item_id)

	print("Current IDs:", current, "Expected IDs:", correct_order)

	if current == correct_order:
		puzzle_solved()

func puzzle_solved() -> void:
	print("Closet puzzle resolvido!")

	for obj in puzzle_objects:
		obj.hide()

	var numeros = ["7", "2", "9", "4"]
	for i in range(labels.size()):
		if labels[i]:
			labels[i].text = numeros[i]
			labels[i].show()
