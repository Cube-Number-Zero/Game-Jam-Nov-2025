extends Control
## This is the node that contains each of the smaller boards, and arranges them in a grid.

const PACKED_BOARD: PackedScene = preload("res://Scenes/board.tscn")

static var meta_grid_dimensions: Vector2i = Vector2i(3, 3) ## H0w many boards are in the game?


func _ready() -> void:
	$Grid.columns = meta_grid_dimensions.x
	
	# Create boards
	for i in range(meta_grid_dimensions.x * meta_grid_dimensions.y):
		var real_board := PACKED_BOARD.instantiate()
		$Grid.add_child(real_board)
	
	calculate_scale()
		

## Resizes the game world to fit the screen.
func calculate_scale() -> void:
	self.custom_minimum_size.x = self.size.y
	var single_board_width: int = Board.TILE_SIZE * Board.BOARD_DIMENSIONS_CELLS
	var boards_dimensions: Vector2i = single_board_width * meta_grid_dimensions
	var scale_x: float = self.size.x / boards_dimensions.x
	var scale_y: float = self.size.y / boards_dimensions.y
	var scale_min: float = minf(scale_x, scale_y)
	for board: Board in $Grid.get_children():
		board.custom_minimum_size = Vector2.ONE * Board.TILE_SIZE * Board.BOARD_DIMENSIONS_CELLS * scale_min
	call_deferred(&"resize_boards", scale_min)
	

func resize_boards(board_scale: float) -> void:
	for board: Board in $Grid.get_children():
		board.get_child(0).scale = Vector2(board_scale, board_scale)

func _on_resized() -> void:
	calculate_scale()
