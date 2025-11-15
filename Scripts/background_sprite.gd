extends Sprite2D

@onready var menu_base = get_parent()
var x_scale: float

#func _ready() -> void:
#	resize_sprite(x_scale)

func resize_sprite(scale: float) -> void:
	var sprite_x = menu_base.get_size().x
	#var sprite_y = get_size().y
	#set_size(Vector2(sprite_x,sprite_y))
	apply_scale(Vector2(scale,1))
	
func _process(_delta):
	pass
	#var sprite_x = menu_base.get_size().x
	
	
	
