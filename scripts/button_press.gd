extends InteractiveObject
class_name ButtonPress

signal button_pressed(color: Color)

@onready var mesh: MeshInstance3D = $Model/Button_Cyrcle_1_Button/Button_Cyrcle_1_Button_Button_Cyrcle_1_0

@export var initial_color: Color = Color("#ffffff")
@export var colors: Array[Color] = [
	Color("#ffffff"),
	Color("#800080"),
	Color("#00ff00"),
	Color("#0000ff"),
	Color("#ff0000"),
	Color("#000000")
]

var material_instance: StandardMaterial3D 

var current_color_index: int = 0
var is_disabled: bool = false

func _ready():
	if mesh and mesh.get_active_material(0) is StandardMaterial3D:
		material_instance = mesh.get_active_material(0).duplicate() as StandardMaterial3D
		
		mesh.set_surface_override_material(0, material_instance)
		
		material_instance.albedo_color = initial_color
		current_color_index = colors.find(initial_color)
		if current_color_index == -1:
			current_color_index = 0
	
	_set_interaction_enabled(false)

func get_current_color() -> Color:
	return colors[current_color_index]

func interact(_action: String = "") -> void:
	if is_disabled:
		return
	
	_change_color()
	emit_signal("button_pressed", get_current_color())

func _change_color() -> void:
	if not material_instance:
		return
		
	current_color_index = (current_color_index + 1) % colors.size()
	material_instance.albedo_color = colors[current_color_index]

func _set_interaction_enabled(enabled: bool):
	is_disabled = not enabled
	var collider = get_node_or_null("CollisionShape3D")
	if collider:
		collider.disabled = not enabled

func disable_button() -> void:
	_set_interaction_enabled(false)
