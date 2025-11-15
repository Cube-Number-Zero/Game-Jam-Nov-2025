extends Node2D

@onready var start_button = get_node("title_canvas/start_button")
@onready var quit_button = get_node("title_canvas/quit_button")
@onready var title_base = get_node("title_canvas")

func _ready() -> void:
	pass
	get_tree().paused = true
	
func _on_start() -> void:
	title_base.set_visible(false)
	get_tree().paused = false
	
func _on_quit() -> void:
	get_tree().quit()
