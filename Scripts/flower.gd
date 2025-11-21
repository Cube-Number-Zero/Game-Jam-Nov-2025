class_name Flower extends Node2D

enum FlowerType {FLOWER_COLOR_1, FLOWER_COLOR_2, FLOWER_COLOR_3}

const FLOWER_TYPES: Array[FlowerType] = [FlowerType.FLOWER_COLOR_1, FlowerType.FLOWER_COLOR_2, FlowerType.FLOWER_COLOR_3]

const PARTICLE_TEXTURES: Dictionary[FlowerType, Resource] = {
	FlowerType.FLOWER_COLOR_1: preload("res://Assets/flowerparticle1.png"),
	FlowerType.FLOWER_COLOR_2: preload("res://Assets/flowerparticle2.png"),
	FlowerType.FLOWER_COLOR_3: preload("res://Assets/flowerparticle3.png")
}

var type: FlowerType

var cell: Vector2i

const FLOWER_REMOVAL_CHANCE: float = 0.1 ## The odds this flower will be removed when FlowerRemovalTimer expires, if possible

func start_particles() -> void:
	$CPUParticles2D.texture = PARTICLE_TEXTURES[type]
	$CPUParticles2D.call_deferred(&"restart")
	
	# Move AlertLabel if at the top of the board
	if cell.y == 0:
		$AlertLabel.position.y = 12.5

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


func _on_cpu_particles_2d_finished() -> void:
	$CPUParticles2D.queue_free()

func set_alert_visibility(alert: bool) -> void:
	$AlertLabel.visible = alert
	
