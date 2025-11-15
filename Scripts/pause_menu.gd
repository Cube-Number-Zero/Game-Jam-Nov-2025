extends Control

const volume_icon = preload("res://Assets/SoundIcon.png")
const mute_icon = preload("res://Assets/SoundIconDisabled.png")

@onready var volume_slider = get_node("background_base/volume_slider")
@onready var volume_button = get_node("background_base/volume_button")
@onready var restart_button = get_node("background_base/restart_button")
@onready var transition = get_node("../../../../ScreenWipe/ScreenWipe")

var restarting: bool = false
var restarted: bool = false
var muted: bool = false
var cur_volume: float = 50.0

func _ready() -> void:
	volume_slider.set_value(cur_volume)
	pass
	
func _on_mute() -> void:
	if (muted == false):
		muted = true
		cur_volume = volume_slider.get_value()
		volume_slider.set_value(0)
		volume_button.set_texture_normal(mute_icon)
	else:
		muted = false
		if (cur_volume == 0.0):
			cur_volume = 1.0
		volume_slider.set_value(cur_volume)
			
		volume_button.set_texture_normal(volume_icon)

func _on_volume_change(_value_changed: bool) -> void:
	if (volume_slider.get_value() == 0):
		_on_mute()
	elif (muted == true):
		muted = false
		volume_button.set_texture_normal(volume_icon)
		
func _on_restart() -> void:
	restarting = true
	transition.game_restarting = true
	transition.transition()
	#get_node("../../../../TitleScreen/title_canvas").set_visible(true)
	#get_tree().reload_current_scene()
	
func _process(_delta) ->void:
	if (get_node("background_base").visible == true):
		if transition.transition_done and restarting == true:
			print("transition done")
			transition.transition_done = false
			restarted = true
			get_node("../../../../TitleScreen/title_canvas").set_visible(true)
			transition.trans_return()
			get_tree().reload_current_scene()
		elif restarted == true and restarting == true:
			print("transition done")
			get_tree().reload_current_scene()
		else:
			pass
	else:
		pass
