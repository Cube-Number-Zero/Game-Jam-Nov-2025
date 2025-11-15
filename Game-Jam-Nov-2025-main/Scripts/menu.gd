extends Control

@onready var erase_button = get_node("background_base/erase_button")
@onready var pause_button = get_node("background_base/pause_button")
@onready var pause_menu = get_node("background_base/pause_menu")
@onready var time_left = get_node("background_base/time_left_progress_bar")

@onready var score = 0

func _ready() -> void:
	#pause_button.pressed.connect(_on_pause)
	pause_menu.set_visible(false)
	
func _on_pause() -> void:
	if (pause_menu.visible == false):
		get_tree().paused = true
		pause_menu.set_visible(true)
		erase_button.set_disabled(true)
	else:
		get_tree().paused = false
		pause_menu.set_visible(false)
		erase_button.set_disabled(false)

func _on_erase(toggled_on: bool) -> void:
	if (toggled_on == true): # we are erasing
		#icon is changed to draw icon
		#link to do erasing?
		print("erasing paths")
	else: #we are drawing
		#icon is changed to erase icon
		#do drawing?
		print("drawing paths")
		
func gameover(final_score: int) -> void:
	get_node("../../GameOverScreen").game_done(final_score)
	
		
func _process(_delta) -> void:
	score = get_node("background_base/score_text_label").score_value
	if (time_left.get_value() <= 0):
		gameover(score)
	if(Input.is_action_just_pressed("gameover")):
		gameover(score)
