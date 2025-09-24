# MainMenu.gd
extends Control

@onready var logo: TextureRect = $MarginContainer2/Logo
@onready var menu_buttons: HBoxContainer = $MarginContainer/MenuButtons
@onready var start_button: Button = $MarginContainer/MenuButtons/StartButton
@onready var quit_button: Button = $MarginContainer/MenuButtons/QuitButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	
	animate_entry()


func animate_entry():
	logo.modulate.a = 0.0
	logo.scale = Vector2(1.2, 1.2)
	menu_buttons.modulate.a = 0.0

	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(logo, "modulate:a", 1.0, 1.0).from(0.0)
	tween.tween_property(logo, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_BACK)

	await tween.finished

	var buttons_tween = create_tween()
	buttons_tween.tween_property(menu_buttons, "modulate:a", 1.0, 0.5)


func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")


func _on_quit_button_pressed():
	get_tree().quit()
