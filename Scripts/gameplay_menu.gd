extends Control

static var meta_grid_dimensions: Vector2i = Vector2i(2, 2) ## How many boards are in the game?

const PACKED_BOARD: PackedScene = preload("res://Scenes/board.tscn")

#@onready var game_grid = get_node("../GameField")
@onready var game_window = get_parent()
@onready var game_field = get_node("../../GameField")

var readied = false


func _ready() -> void:
	#print("here")
	#print(game_window)
	#print(game_field)
		
	calculate_scale()
	readied = true

## Resizes the menu to fit the screen?
func calculate_scale() -> void:
	var window_size_x = game_window.get_position().x - 10
	var window_size_y = game_window.get_size().y
	var game_size = game_field.get_size()
	var menu_x = window_size_x - game_size.x
	var scale_x = menu_x / window_size_x
	call_deferred(&"resize_menu", menu_x, window_size_y)#scale_x, 1)
	

func resize_menu(x_scale: float, y_scale: float) -> void:
	#self.set_scale(Vector2(x_scale, y_scale))
	self.set_size(Vector2(x_scale, y_scale))
	#get_node("background_base").set_scale(Vector2(x_scale, y_scale))
	get_node("background_base").set_size(Vector2(x_scale, y_scale))
	#for child in get_node("background_base").get_children():
	#	child.set_scale(get_node("background_base").get_scale())

func _on_resized() -> void:
	if (readied == false):
		pass
	else:
		calculate_scale()
		
