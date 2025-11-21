class_name GameField extends Control
## This is the node that contains each of the smaller boards, and arranges them in a grid.

const PACKED_BOARD: PackedScene = preload("res://Scenes/board.tscn")

static var meta_grid_dimensions := Vector2i(2, 2) ## How many boards are in the game?

# i changed this one - i hope it dont fuck up
static var disconnected_regions: Dictionary[Flower.FlowerType, int] = {
	Flower.FlowerType.FLOWER_COLOR_1: 0,
	Flower.FlowerType.FLOWER_COLOR_2: 0,
	Flower.FlowerType.FLOWER_COLOR_3: 0
}

var flower_lists: Dictionary[Flower.FlowerType, Array] = {
	Flower.FlowerType.FLOWER_COLOR_1: [],
	Flower.FlowerType.FLOWER_COLOR_2: [],
	Flower.FlowerType.FLOWER_COLOR_3: []
}

func now_ready() -> void:
	$Grid.columns = meta_grid_dimensions.x
	
	# Create boards
	for i in range(meta_grid_dimensions.x * meta_grid_dimensions.y):
		var real_board := PACKED_BOARD.instantiate()
		$Grid.add_child(real_board)
	
	calculate_scale()
	
	for type: Flower.FlowerType in [Flower.FlowerType.FLOWER_COLOR_1, Flower.FlowerType.FLOWER_COLOR_2, Flower.FlowerType.FLOWER_COLOR_3]:
		var board: Board = $Grid.get_children().pick_random()
		board.create_flower_at_random_location(type)
		board.create_flower_at_random_location(type)

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_erase"):
		#Board.erase_mode = not Board.erase_mode
		$"../HBoxContainer/GameplayMenu"._on_erase(!Board.erase_mode)


func create_random_flower() -> void:
	var type: Flower.FlowerType = [Flower.FlowerType.FLOWER_COLOR_1, Flower.FlowerType.FLOWER_COLOR_2, Flower.FlowerType.FLOWER_COLOR_3].pick_random()
	var possible_boards: Array[Board] = []
	for flower: Flower in flower_lists[type]:
		var board: Board = flower.get_node(^"../..")
		if not board in possible_boards:
			possible_boards.append(board)
	
	var new_possible_boards: Array[Board] = possible_boards.duplicate()
	while len(new_possible_boards):
		for portal: Portal in new_possible_boards[0].get_node(^"Portals").get_children():
			var board2: Board = portal.linked_portal.get_node(^"../..")
			if not board2 in possible_boards:
				possible_boards.append(board2)
				new_possible_boards.append(board2)
		new_possible_boards.erase(new_possible_boards[0])
	
	var used_board: Board = possible_boards.pick_random()
	
	used_board.create_flower_at_random_location(type)
	check_disconnected_regions(type)
	

func create_random_portals() -> void:
	
	# Find locations
	var attempts_left: int = 16
	var coords1 := Vector3i(-1, -1, -1)
	var coords2 := Vector3i(-1, -1, -1)
	while coords1 == Vector3i(-1, -1, -1):
		var board: Board = $Grid.get_children().pick_random()
		var x: int = randi_range(0, Board.board_dimensions_cells - 1)
		var y: int = randi_range(0, Board.board_dimensions_cells - 1)
		if x in [0, Board.board_dimensions_cells - 1] and y in [0, Board.board_dimensions_cells - 1]:
			# In a corner
			continue
		elif board.is_empty_at_cell(Vector2i(x, y)):
			coords1 = Vector3i(x, y, board.z_dimension)
		else:
			attempts_left -= 1
			if not attempts_left: return # Board was too full. Fail.
	while coords2 == Vector3i(-1, -1, -1):
		var board: Board = $Grid.get_children().pick_random()
		var x: int = randi_range(0, Board.board_dimensions_cells - 1)
		var y: int = randi_range(0, Board.board_dimensions_cells - 1)
		if x in [0, Board.board_dimensions_cells - 1] and y in [0, Board.board_dimensions_cells - 1]:
			# In a corner
			continue
		elif coords1 == Vector3i(x, y, board.z_dimension):
			attempts_left -= 1
			if not attempts_left: return # Board was too full. Fail.
		elif board.is_empty_at_cell(Vector2i(x, y)):
			coords2 = Vector3i(x, y, board.z_dimension)
		else:
			attempts_left -= 1
			if not attempts_left: return # Board was too full. Fail.
	
	# Create portal!
	var portal1: Portal = Board.boards[coords1.z].create_portal(coords1.x, coords1.y)
	var portal2: Portal = Board.boards[coords2.z].create_portal(coords2.x, coords2.y)
	Portal.link_portals(portal1, portal2)
	Portal.update_colors()
	check_all_disconnected_regions()

## Resizes the game world to fit the screen.
func calculate_scale() -> void:
	self.custom_minimum_size.x = self.size.y
	var single_board_width: int = Board.TILE_SIZE * Board.board_dimensions_cells
	var boards_dimensions: Vector2i = single_board_width * meta_grid_dimensions
	var scale_x: float = self.size.x / boards_dimensions.x
	var scale_y: float = self.size.y / boards_dimensions.y
	var scale_min: float = minf(scale_x, scale_y)
	for board: Board in $Grid.get_children():
		board.custom_minimum_size = Vector2.ONE * Board.TILE_SIZE * Board.board_dimensions_cells * scale_min
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
	var regions: Array[Array] = []
	var unreached_flowers: Array = flower_lists[type].duplicate()
	
	while len(unreached_flowers):
		var current_region: Array[Flower] = []
		disconnected_regions[type] += 1
		var connected: Array[Flower] = Board.get_flowers_connected_to_cell(
			Vector3i(	unreached_flowers[0].cell.x,
						unreached_flowers[0].cell.y,
						unreached_flowers[0].get_node(^"../..").z_dimension), type)
		for connected_flower: Flower in connected:
			if not connected_flower in current_region:
				reached_flowers.append(connected_flower)
				current_region.append(connected_flower)
			unreached_flowers.erase(connected_flower)
		regions.append(current_region)
	
	# Check to see which flowers are disconnected
	if len(regions) == 0:
		return

	var largest_region_size: int
	var largest_region_index: int
	
	for region_index: int in range(len(regions)):
		if len(regions[region_index]) > largest_region_size:
			largest_region_index = region_index
			largest_region_size = len(regions[region_index])
	
	# Display alerts above flowers
	
	for flower: Flower in reached_flowers:
		if flower in regions[largest_region_index] and largest_region_size > 1:
			flower.set_alert_visibility(false)
		else:
			flower.set_alert_visibility(true)

func check_all_disconnected_regions() -> void:
	check_disconnected_regions(Flower.FlowerType.FLOWER_COLOR_1)
	check_disconnected_regions(Flower.FlowerType.FLOWER_COLOR_2)
	check_disconnected_regions(Flower.FlowerType.FLOWER_COLOR_3)


func _on_check_islands_timer_timeout() -> void:
	check_all_disconnected_regions()


func _on_portal_spawn_timer_timeout() -> void:
	create_random_portals()


func _on_flower_spawn_timer_timeout() -> void:
	create_random_flower()


func _on_obstacle_spawn_timer_timeout() -> void:
	$Grid.get_children().pick_random().create_obstacle_at_random_location()
