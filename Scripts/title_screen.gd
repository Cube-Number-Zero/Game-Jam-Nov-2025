extends Node2D

@onready var start_button = get_node("title_canvas/start_button")
@onready var quit_button = get_node("title_canvas/quit_button")
@onready var title_base = get_node("title_canvas")
@onready var transition = get_node("../ScreenWipe/ScreenWipe")
@onready var sfx_player = get_node("../SFXAudioPlayer")

#const button_audio = preload("res://Assets/Sound/click.mp3")

func _ready() -> void:
	pass
	get_tree().paused = true
	
func _process(_delta: float) -> void:
	if transition.transition_done:
		title_base.set_visible(false)
		get_tree().paused = false
		transition.transition_done = false
		transition.trans_return()
	
func _on_start() -> void:
	sfx_player.play()
	transition.transition()
	
func _on_quit() -> void:
	sfx_player.play()
	get_tree().quit()
