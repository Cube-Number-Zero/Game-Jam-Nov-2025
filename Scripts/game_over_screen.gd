extends Node2D

@onready var restart_button = get_node("gameover_canvas/restart_button")
@onready var quit_button = get_node("gameover_canvas/quit_button")
@onready var gameover_base = get_node("gameover_canvas")
@onready var score_text = get_node("gameover_canvas/final_score_text")
@onready var transition = get_node("../ScreenWipe/ScreenWipe")
@onready var image = get_node("gameover_canvas/background")
@onready var music_player = get_node("../AudioStreamPlayer")
@onready var sfx_player = get_node("../SFXAudioPlayer")

const bad_image = preload("res://Assets/KG_GameJam_GameOver.png")
const mid_image = preload("res://Assets/KG_GameJam_mid.png")
const good_image = preload("res://Assets/KG_GameJam_good.png")

const gameover_theme_intro = preload("res://Assets/Sound/Credits Theme - Intro.ogg")
const gameover_theme = preload("res://Assets/Sound/Credits Theme - Loop.ogg")


var restarting: bool = false
var restarted: bool = false

func _ready() -> void:
	gameover_base.set_visible(false)

func _on_restart() -> void:
	sfx_player.play()
	restarting = true
	transition.game_restarting = true
	transition.transition()

func _on_quit() -> void:
	sfx_player.play()
	get_tree().quit()
	
func game_done(score: int) -> void:
	get_tree().paused = true
	music_player.stop()
	music_player.set_stream(gameover_theme_intro)
	music_player.play()
	if score <= 200:
		image.set_texture(bad_image)
	elif score <= 500:
		image.set_texture(mid_image)
	else:
		image.set_texture(good_image)
		
	gameover_base.set_visible(true)
	var text_str
	text_str = "Your Final Score Is: %d" % score
	score_text.set_text(text_str)
	transition.trans_return()
	
func _process(_delta) ->void:
	if transition.transition_done and restarting == true:
		#print("transition done")
		transition.transition_done = false
		restarted = true
		get_node("../TitleScreen/title_canvas").set_visible(true)
		gameover_base.set_visible(false)
		transition.trans_return()
		transition.static_restart()
		get_tree().reload_current_scene()
	elif restarted == true and restarting == true:
		#print("transition done")
		transition.static_restart()
		get_tree().reload_current_scene()
	elif transition.transition_done:
		get_node("../TitleScreen/title_canvas").set_visible(true)
		transition.static_restart()
		get_tree().reload_current_scene()
	else:
		pass
		
	

func _on_audio_finished() -> void:
	print("finished - outsidr loop")
	if (music_player.get_stream() == gameover_theme_intro):
		print("inside loop")
		music_player.set_stream(gameover_theme)
		music_player.play()
