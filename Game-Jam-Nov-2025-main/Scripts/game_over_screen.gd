extends Node2D

@onready var restart_button = get_node("gameover_canvas/restart_button")
@onready var quit_button = get_node("gameover_canvas/quit_button")
@onready var gameover_base = get_node("gameover_canvas")
@onready var score_text = get_node("gameover_canvas/final_score_text")


func _ready() -> void:
	gameover_base.set_visible(false)

func _on_restart() -> void:
	get_node("../TitleScreen/title_canvas").set_visible(true)
	get_tree().reload_current_scene()
	#get_tree().paused = true

func _on_quit() -> void:
	get_tree().quit()
	
func game_done(score: int) -> void:
	get_tree().paused = true
	gameover_base.set_visible(true)
	var text_str
	text_str = "Your Final Score Is:
		%d" % score
	score_text.set_text(text_str)
	
