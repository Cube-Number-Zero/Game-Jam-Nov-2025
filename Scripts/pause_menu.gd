extends Control

const volume_icon = preload("res://Assets/SoundIcon.png")
const mute_icon = preload("res://Assets/SoundIconDisabled.png")

@onready var volume_slider = get_node("background_base/volume_slider")
@onready var volume_button = get_node("background_base/volume_button")
@onready var restart_button = get_node("background_base/restart_button")
@onready var transition = get_node("../../../../ScreenWipe/ScreenWipe")
@onready var audio_player = get_node("../../../../AudioStreamPlayer")
@onready var sfx_player = get_node("../../../../SFXAudioPlayer")
@onready var gameplay_menu = get_node("../../../GameplayMenu")

var restarting: bool = false
var restarted: bool = false
var muted: bool = false
var cur_volume: float = 30.0

func _ready() -> void:
	volume_slider.set_value(cur_volume)
	audio_player.set_volume_linear(volume_slider.get_value()/2)
	sfx_player.set_volume_linear(volume_slider.get_value()/2)
	pass
	
func _on_mute() -> void:
	sfx_player.play()
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
	audio_player.set_volume_linear(volume_slider.get_value()/2)
	sfx_player.set_volume_linear(volume_slider.get_value()/2)

func _on_volume_change(_value_changed: bool) -> void:
	if (volume_slider.get_value() == 0):
		_on_mute()
	elif (muted == true):
		muted = false
		volume_button.set_texture_normal(volume_icon)
	audio_player.set_volume_linear(volume_slider.get_value()/2)
	sfx_player.set_volume_linear(volume_slider.get_value()/2)
		
func _on_restart() -> void:
	sfx_player.play()
	restarting = true
	transition.game_restarting = true
	transition.transition()
	
func _process(_delta) ->void:
	if (get_node("background_base").visible == true):
		if transition.transition_done and restarting == true:
			print("transition done")
			transition.transition_done = false
			restarted = true
			get_node("../../../../TitleScreen/title_canvas").set_visible(true)
			transition.trans_return()
			transition.static_restart()
			get_tree().reload_current_scene()
		elif restarted == true and restarting == true:
			print("transition done")
			transition.tatic_restart()
			get_tree().reload_current_scene()
		else:
			pass
	else:
		pass
	if (Input.is_action_just_pressed("pause")):
		gameplay_menu._on_pause()
