extends RichTextLabel

@onready var timer = get_node("timer")

@export var score_value: int = 0

func _on_timer_timeout() -> void:
	score_value += 10
	#get_node("../../../gameplay_menu").check_flowers()

func _process(_delta):
	var text_str
	text_str = "Score: %d" % score_value
	set_text(text_str)
	
