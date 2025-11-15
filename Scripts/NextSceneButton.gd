extends TextureButton

@onready var timer = $TransitionTimer
@onready var timerTime = timer.wait_time
var ogScale = scale

func _process(_delta: float) -> void:
	var started = timer.time_left < timerTime and timer.time_left != 0
	
	if started:
		var newScale
		var amount = timerTime - timer.time_left
		#var lastScale = scale
		var bigger = ogScale + Vector2(.1,.1)
		if amount < timerTime/3:
			newScale = lerp(ogScale,bigger,amount*100)
		if amount >= timerTime/3:
			newScale = lerp(bigger,ogScale,(amount-timerTime/2)*5)
		newScale = newScale.clamp(ogScale,bigger)
		
		#var differenceVector = newScale - lastScale
		
		scale = newScale


func _on_button_down() -> void:
	timer.start(1)
