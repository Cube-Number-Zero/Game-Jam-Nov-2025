extends Node2D

@onready var restart_button = get_node("gameover_canvas/restart_button")
@onready var quit_button = get_node("gameover_canvas/quit_button")
@onready var gameover_base = get_node("gameover_canvas")
@onready var score_text = get_node("gameover_canvas/final_score_text")
@onready var transition = get_node("../ScreenWipe/ScreenWipe")

var restarting: bool = false
var restarted: bool = false

func _ready() -> void:
	gameover_base.set_visible(false)

func _on_restart() -> void:
	restarting = true
	transition.game_restarting = true
	transition.transition()
	#get_node("../TitleScreen/title_canvas").set_visible(true)
	#get_tree().reload_current_scene()

func _on_quit() -> void:
	get_tree().quit()
	
func game_done(score: int) -> void:
	get_tree().paused = true
	gameover_base.set_visible(true)
	var text_str
	text_str = "Your Final Score Is: %d" % score
	score_text.set_text(text_str)
	transition.trans_return()
	
func _process(_delta) ->void:
	if transition.transition_done and restarting == true:
		print("transition done")
		transition.transition_done = false
		restarted = true
		get_node("../TitleScreen/title_canvas").set_visible(true)
		gameover_base.set_visible(false)
		transition.trans_return()
		get_tree().reload_current_scene()
	elif restarted == true and restarting == true:
		print("transition done")
		get_tree().reload_current_scene()
	elif transition.transition_done:
		get_node("../TitleScreen/title_canvas").set_visible(true)
		get_tree().reload_current_scene()
	else:
		pass
	
