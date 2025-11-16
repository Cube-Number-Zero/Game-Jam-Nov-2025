class_name Flower extends Node2D

enum FlowerType {FLOWER_COLOR_1, FLOWER_COLOR_2, FLOWER_COLOR_3}

const FLOWER_TYPES: Array[Flower.FlowerType] = [Flower.FlowerType.FLOWER_COLOR_1, Flower.FlowerType.FLOWER_COLOR_2, Flower.FlowerType.FLOWER_COLOR_3]

var type: FlowerType

var cell: Vector2i

const FLOWER_REMOVAL_CHANCE: float = 0.4 ## The odds this flower will be removed when FlowerRemovalTimer expires, if possible

func check_for_flower_decay() -> void:
	var connections: int = $"../..".count_flower_connections(cell)
	if connections <= 2: # Viable for check for flower decay
		$"../..".remove_flower(cell)


func _on_flower_removal_timer_timeout() -> void:
	if randf() <= FLOWER_REMOVAL_CHANCE:
		check_for_flower_decay()
