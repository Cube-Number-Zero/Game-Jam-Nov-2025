extends Control

@onready var erase_button = get_node("background_base/erase_button")
@onready var pause_button = get_node("background_base/pause_button")
@onready var pause_menu = get_node("background_base/pause_menu")
@onready var time_left = get_node("background_base/time_left_progress_bar")
@onready var transition = get_node("../../ScreenWipe/ScreenWipe")
@onready var health_bar = get_node("background_base/time_left_progress_bar")

const erase_icon = preload("res://Assets/eraserbutton.png")
const draw_icon = preload("res://Assets/brsuhbutton.png")
var move_gameover: bool = false
var stopit: bool = false

@onready var score = 0

var flower_1_regions = GameField.disconnected_regions[Flower.FlowerType.FLOWER_COLOR_1]
var flower_2_regions = GameField.disconnected_regions[Flower.FlowerType.FLOWER_COLOR_2]
var flower_3_regions = GameField.disconnected_regions[Flower.FlowerType.FLOWER_COLOR_3]
var health_left: float = 100.0
var remove_health: float = 0.0

func _ready() -> void:
	health_bar.set_value(health_left)
	pause_menu.set_visible(false)
	pause_button.get_child(0).bbcode_enabled = true
	
func _on_pause() -> void:
	if (pause_menu.visible == false):
		get_tree().paused = true
		pause_menu.set_visible(true)
		erase_button.set_disabled(true)
		pause_button.get_child(0).bbcode_text = "[color=#cb8028]Unpause[/color]" #yellow color
	else:
		get_tree().paused = false
		pause_menu.set_visible(false)
		erase_button.set_disabled(false)
		pause_button.get_child(0).set_text("Pause")

func _on_erase(toggled_on: bool) -> void:
	if (toggled_on == true): # we are erasing
		#icon is changed to draw icon
		erase_button.set_texture_normal(draw_icon)
		#link to do erasing?
		Board.erase_mode = true
		
	else: #we are drawing
		#icon is changed to erase icon
		erase_button.set_texture_normal(erase_icon)
		Board.erase_mode = false
		#do drawing?
		
		
func gameover(final_score: int) -> void:
	#print("game over called")
	stopit = true
	move_gameover = true
	transition.transition()
	score = final_score
	#get_node("../../GameOverScreen").game_done(final_score)
	
	
func check_flowers() -> void:
	var amount = 0
	if flower_1_regions > 1:
		amount += 1
	if flower_2_regions > 1:
		amount += 1
	if flower_3_regions > 1:
		amount +=1
	print(amount)
	if amount > 0:
		decrease_health(amount)
	else:
		increase_health()
	#health_bar.set_value(health_left)
	#print(health_bar.get_value())
		
		
func decrease_health(amount: int) -> void:
	print("decreasing")
	if (amount == 1):
		remove_health = 1
	elif (amount == 2):
		remove_health = 2
	else: #(amount == 3):
		remove_health = 5
		
func increase_health() -> void:
	print("increasing")
	if (health_left >= 75):
		remove_health = -2
	elif (health_left >= 50):
		remove_health = -4
	elif (health_left >= 25):
		remove_health = -6
	else:
		remove_health = -8
	
		
func _process(delta) -> void:
	score = get_node("background_base/score_text_label").score_value
	flower_1_regions = GameField.disconnected_regions[Flower.FlowerType.FLOWER_COLOR_1]
	flower_2_regions = GameField.disconnected_regions[Flower.FlowerType.FLOWER_COLOR_2]
	flower_3_regions = GameField.disconnected_regions[Flower.FlowerType.FLOWER_COLOR_3]
	health_left -= (remove_health * delta)/2
	health_bar.set_value(health_left)
	
	if stopit == false:
		if (time_left.get_value() <= 0):
			if move_gameover == false:
				gameover(score)
	if(Input.is_action_just_pressed("gameover")):
		gameover(score)
	if transition.transition_done and (move_gameover == true):
		stopit = true
		move_gameover = false
		get_node("../../GameOverScreen").game_done(score)
