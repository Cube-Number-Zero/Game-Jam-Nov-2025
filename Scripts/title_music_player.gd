extends AudioStreamPlayer

@onready var title = get_node("../title_canvas")

func _ready() -> void:
	set_volume_linear(15)

func _process(_delta) -> void:
	if title.visible == true and playing == false:
		play()
	elif title.visible == false and playing == true:
		stop()
