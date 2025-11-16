class_name Flower extends Node2D

enum FlowerType {FLOWER_COLOR_1, FLOWER_COLOR_2, FLOWER_COLOR_3}

const FLOWER_TYPES: Array[Flower.FlowerType] = [Flower.FlowerType.FLOWER_COLOR_1, Flower.FlowerType.FLOWER_COLOR_2, Flower.FlowerType.FLOWER_COLOR_3]

var type: FlowerType

var cell: Vector2i

const FLOWER_REMOVAL_CHANCE: float = 0.2 ## The odds this flower will be removed when FlowerRemovalTimer expires, if possible

func check_for_flower_decay() -> void:
	var connections: int = $"../..".count_flower_connections(cell)
	if 0 < connections and connections <= 2: # Viable for check for flower decay
		$"../..".remove_flower(cell)
		queue_free()
		$"../../../..".flower_lists[type].erase(self)


func _on_flower_removal_timer_timeout() -> void:
	if randf() <= FLOWER_REMOVAL_CHANCE:
		if len($"../../../..".flower_lists[type]) > 3: # Don't erase flowers when there are fewer than three of thi type
			check_for_flower_decay()
