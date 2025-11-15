class_name GameField extends Control
## This is the node that contains each of the smaller boards, and arranges them in a grid.

const PACKED_BOARD: PackedScene = preload("res://Scenes/board.tscn")

static var meta_grid_dimensions: Vector2i = Vector2i(2, 2) ## How many boards are in the game?

var disconnected_regions: Dictionary[Flower.FlowerType, int] = {
	Flower.FlowerType.FLOWER_COLOR_1: 0,
	Flower.FlowerType.FLOWER_COLOR_2: 0,
	Flower.FlowerType.FLOWER_COLOR_3: 0
}

var flower_lists: Dictionary[Flower.FlowerType, Array] = {
	Flower.FlowerType.FLOWER_COLOR_1: [],
	Flower.FlowerType.FLOWER_COLOR_2: [],
	Flower.FlowerType.FLOWER_COLOR_3: []
}

func _ready() -> void:
	$Grid.columns = meta_grid_dimensions.x
	
	# Create boards
	for i in range(meta_grid_dimensions.x * meta_grid_dimensions.y):
		var real_board := PACKED_BOARD.instantiate()
		$Grid.add_child(real_board)
	
	calculate_scale()
	
	#Create a portal pair for testing
	
	for i in range(8):
	
		Portal.link_portals(
			$Grid.get_child(randi_range(0, meta_grid_dimensions.x * meta_grid_dimensions.y - 1)).create_portal(
				randi_range(0, Board.BOARD_DIMENSIONS_CELLS - 1), randi_range(0, Board.BOARD_DIMENSIONS_CELLS - 1)),
			$Grid.get_child(randi_range(0, meta_grid_dimensions.x * meta_grid_dimensions.y - 1)).create_portal(
				randi_range(0, Board.BOARD_DIMENSIONS_CELLS - 1), randi_range(0, Board.BOARD_DIMENSIONS_CELLS - 1))
		)
		Portal.update_colors()

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
		for child in board.get_children():
			child.scale = Vector2(board_scale, board_scale)

func _on_resized() -> void:
	calculate_scale()



func check_disconnected_regions(type: Flower.FlowerType) -> void:
	disconnected_regions[type] = 0
	if len(flower_lists[type]) == 0:
		return
	var reached_flowers: Array[Flower] = []
	var unreached_flowers: Array = flower_lists[type].duplicate()
	
	while len(unreached_flowers):
		disconnected_regions[type] += 1
		var connected: Array[Flower] = Board.get_flowers_connected_to_cell(
			Vector3i(unreached_flowers[0].cell.x, unreached_flowers[0].cell.y, unreached_flowers[0].get_node(^"../..").z_dimension),
			type)
		for connected_flower: Flower in connected:
			assert(not connected_flower in reached_flowers)
			reached_flowers.append(connected_flower)
			unreached_flowers.erase(connected_flower)

func check_all_disconnected_regions() -> void:
	check_disconnected_regions(Flower.FlowerType.FLOWER_COLOR_1)
	check_disconnected_regions(Flower.FlowerType.FLOWER_COLOR_2)
	check_disconnected_regions(Flower.FlowerType.FLOWER_COLOR_3)


func _on_check_islands_timer_timeout() -> void:
	check_all_disconnected_regions()
