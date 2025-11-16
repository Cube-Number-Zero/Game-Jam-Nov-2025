class_name Obstacle extends Node2D

var cell: Vector2i

const OBSTACLE_REMOVAL_CHANCE: float = 0.05

func _ready() -> void:
	$Sprite2D.region_rect.position.x = randi_range(0, 4) * 26.0

func remove_obstacle() -> void:
	$"../..".delete_obstacle(cell)
	self.queue_free()

func _on_obstacle_removal_timer_timeout() -> void:
	if randf() <= OBSTACLE_REMOVAL_CHANCE:
		remove_obstacle()
