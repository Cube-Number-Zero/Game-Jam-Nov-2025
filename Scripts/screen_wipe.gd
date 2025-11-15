extends TextureRect

var SceneToTransitionTo = ""

@onready var timer = $TransitionTimer
@onready var animationPlayer = $AnimationPlayer

@export var transition_done: bool = false
@export var game_restarting: bool = false

func transition():#nextScene: String):
	#SceneToTransitionTo = nextScene
	transition_done = false
	timer.start()
	animationPlayer.play("Transition")
	
func trans_return():
	animationPlayer.play("return")

func _ready() -> void:
	animationPlayer.play("return")


func _on_transition_timer_timeout() -> void:
	transition_done = true
	#SceneHandler.changeScene(SceneToTransitionTo)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if (anim_name == "return"):
		transition_done = false
	else:
		transition_done = true
	if game_restarting == true:
		game_restarting = false
		get_tree().reload_current_scene()
