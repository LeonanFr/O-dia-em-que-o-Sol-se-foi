
extends Control

@export var main_game_scene_path: String = "res://scenes/room_01.tscn"

var loading_status: ResourceLoader.ThreadLoadStatus
var animation_finished: bool = false

@onready var quote_label: Label = $BackgroundColor/MarginContainer/QuoteLabel
@onready var loading_circle: TextureRect = $LoadingCircle

func _ready() -> void:
	start_background_loading()
	animate_text()
	
	loading_circle.pivot_offset = loading_circle.size / 2
	var spin_tween = create_tween().set_loops()
	spin_tween.tween_property(loading_circle, "rotation", deg_to_rad(360), 1.5).from(0.0)

func start_background_loading():
	ResourceLoader.load_threaded_request(main_game_scene_path)


func animate_text():
	var full_text = "Os pássaros pararam de cantar. A escuridão tomou conta de nós. Ninguém mais era o mesmo."
	quote_label.text = full_text
	
	var tween = create_tween().set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(quote_label, "visible_ratio", 1.0, 5.0).from(0.0)
	
	await tween.finished
	animation_finished = true
	
	if loading_status != ResourceLoader.THREAD_LOAD_LOADED:
		loading_circle.show()
	
	await get_tree().create_timer(1.5).timeout
	
	check_if_ready_to_transition()


func _process(_delta: float) -> void:
	loading_status = ResourceLoader.load_threaded_get_status(main_game_scene_path)
	
	if loading_status == ResourceLoader.THREAD_LOAD_LOADED:
		check_if_ready_to_transition()


func check_if_ready_to_transition():
	if loading_status == ResourceLoader.THREAD_LOAD_LOADED and animation_finished:
		set_process(false)
		
		loading_circle.hide()
		
		var next_scene = ResourceLoader.load_threaded_get(main_game_scene_path)
		
		var fade_out_tween = create_tween()
		fade_out_tween.tween_property(self, "modulate:a", 0.0, 1.0)
		
		await fade_out_tween.finished
		
		get_tree().change_scene_to_packed(next_scene)
