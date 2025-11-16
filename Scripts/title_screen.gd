extends Node2D

@onready var start_button = get_node("title_canvas/start_button")
@onready var quit_button = get_node("title_canvas/quit_button")
@onready var title_base = get_node("title_canvas")
@onready var transition = get_node("../ScreenWipe/ScreenWipe")
@onready var sfx_player = get_node("../SFXAudioPlayer")

@onready var options_menu = get_node("options_canvas")

#const button_audio = preload("res://Assets/Sound/click.mp3")

func _ready() -> void:
	GameField.meta_grid_dimensions = Vector2i(2, 2)
	Board.board_dimensions_cells = 12
	options_menu.set_visible(false)
	get_tree().paused = true
	
func _process(_delta: float) -> void:
	if transition.transition_done:
		title_base.set_visible(false)
		options_menu.set_visible(false)
		get_tree().paused = false
		transition.transition_done = false
		transition.trans_return()
	
func _on_start() -> void:
	get_node("../GameField").now_ready()
	sfx_player.play()
	transition.transition()
	
func _on_quit() -> void:
	sfx_player.play()
	get_tree().quit()
	
func _on_options() -> void:
	sfx_player.play()
	if (options_menu.visible == false):
		options_menu.visible = true
	else:
		options_menu.visible = false

func _on_large_grid_change(value_changed: bool) -> void:
	if (value_changed == true):
		var value = (int)(options_menu.get_node("background/large_grid_slider").get_value())
		GameField.meta_grid_dimensions = Vector2i(value, value)
		var text = "Large Grid Size: %d x %d" % [value, value]
		options_menu.get_node("big_grid_text").set_text(text)

func _on_small_grid_change(value_changed: bool) -> void:
	if (value_changed == true):
		var value = options_menu.get_node("background/small_grid_slider").get_value()
		Board.board_dimensions_cells = value
		var text = "Small Grid Size: %d x %d" % [value, value]
		options_menu.get_node("small_grid_text").set_text(text)

func _check_grids() -> void:
	var value_l = (int)(options_menu.get_node("background/large_grid_slider").get_value())
	GameField.meta_grid_dimensions = Vector2i(value_l, value_l)
	var text_l = "Large Grid Size: %d x %d" % [value_l, value_l]
	options_menu.get_node("big_grid_text").set_text(text_l)
	var value_s = options_menu.get_node("background/small_grid_slider").get_value()
	Board.board_dimensions_cells = value_s
	var text_s = "Small Grid Size: %d x %d" % [value_s, value_s]
	options_menu.get_node("small_grid_text").set_text(text_s)
