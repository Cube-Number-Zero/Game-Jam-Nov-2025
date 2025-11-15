class_name Board extends Control
## A single board with a tilemap inside. Several of these will be linked together with portals

const TILE_SIZE: int = 25 ## The height/width of tiles, in pixels
const BOARD_DIMENSIONS_CELLS: int = 12 ## The width of the board, in cells


func _ready() -> void:
	self.custom_minimum_size = Vector2.ONE * TILE_SIZE * BOARD_DIMENSIONS_CELLS
