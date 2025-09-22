extends Resource
class_name ItemData

enum ItemType { ACTIVATABLE, DIRECT_USE }
enum ItemCategory { GENERIC, TOOL, LIGHT_SOURCE }

@export var id: String = ""
@export var display_name: String = ""
@export var icon: Texture2D
@export var type: ItemType = ItemType.ACTIVATABLE
@export var category: ItemCategory = ItemCategory.GENERIC
@export var is_collectible: bool = false
