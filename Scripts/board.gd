class_name Board extends Control
## A single board with a tilemap inside. Several of these will be linked together with portals

const PACKED_FLOWER: PackedScene = preload("res://Scenes/flower.tscn")
const PACKED_PORTAL: PackedScene = preload("res://Scenes/portal.tscn")
const PACKED_OBSTACLE: PackedScene = preload("res://Scenes/obstacle.tscn")

const TILE_SIZE: int = 26 ## The height/width of tiles, in pixels
static var board_dimensions_cells: int = 12 ## The width of the board, in cells

var is_drawing: bool = false ## Whether or not the player is currently drawing
static var drawing_type: Flower.FlowerType
var drawing_cell: Vector2i


static var boards: Array[Board] = []
var z_dimension: int

static var erase_mode: bool = false

const EMPTY_ATLAS_COORDS := Vector2i(-1, -1)
const FLOWER_ATLAS_COORDS := Vector2i(0, 0)
const PORTAL_ATLAS_COORDS := Vector2i(4, 0)
const OBSTACLE_ATLAS_COORDS := Vector2i(4, 1)

const ATLAS_INDEX_TO_ATLAS_COORDS: Dictionary[int, Vector2i] = {
	0x1: Vector2i(0, 3),
	0x2: Vector2i(1, 0),
	0x3: Vector2i(1, 2),
	0x4: Vector2i(0, 1),
	0x5: Vector2i(0, 2),
	0x6: Vector2i(1, 1),
	0x8: Vector2i(3, 0),
	0x9: Vector2i(2, 2),
	0xA: Vector2i(2, 0),
	0xC: Vector2i(2, 1),
}

const ATLAS_COORDS_TO_ATLAS_INDEX: Dictionary[Vector2i, int] = {
	Vector2i(0, 3): 0x1,
	Vector2i(1, 0): 0x2,
	Vector2i(1, 2): 0x3,
	Vector2i(0, 1): 0x4,
	Vector2i(0, 2): 0x5,
	Vector2i(1, 1): 0x6,
	Vector2i(3, 0): 0x8,
	Vector2i(2, 2): 0x9,
	Vector2i(2, 0): 0xA,
	Vector2i(2, 1): 0xC,
}

const VECTOR_TO_ATLAS_INDEX: Dictionary[Vector2i, int] = {
	Vector2i( 0, 1): 0x4,
	Vector2i( 1, 0): 0x2,
	Vector2i( 0,-1): 0x1,
	Vector2i(-1, 0): 0x8
}

const INVERT_ATLAS_INDEX: Dictionary[int, int] = {
	0x1: 0x4,
	0x2: 0x8,
	0x4: 0x1,
	0x8: 0x2
}

const DRAWABLE_ATLAS_CELLS_1: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(3, 0), Vector2i(0, 1), Vector2i(0, 3)]
const DRAWABLE_ATLAS_CELLS_2: Array[Vector2i] = [
	Vector2i(0, 4), Vector2i(1, 4), Vector2i(3, 4), Vector2i(0, 5), Vector2i(0, 7)]
const DRAWABLE_ATLAS_CELLS_3: Array[Vector2i] = [
	Vector2i(0, 8), Vector2i(1, 8), Vector2i(3, 8), Vector2i(0, 9), Vector2i(0, 11)]
## If a cell's atlas coords is in this list, the player can draw more tiles from there


const OVERPASS_ATLAS_CELLS: Array[Vector2i] = [Vector2i(3, 1), Vector2i(3, 2), Vector2i(1, 3), Vector2i(2, 3)]
const OVERPASS_ATLAS_CELLS_HORIZONTAL: Array[Vector2i] = [Vector2i(3, 1), Vector2i(3, 2)]
const OVERPASS_ATLAS_CELLS_VERTICAL: Array[Vector2i] = [Vector2i(1, 3), Vector2i(2, 3)]

const STRAIGHT_ATLAS_CELLS: Array[Vector2i] = [Vector2i(0, 2), Vector2i(2, 0), Vector2i(0, 6), Vector2i(2, 4), Vector2i(0,10), Vector2i(2, 8)]
const DEAD_ENDS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(3, 0), Vector2i(0, 1), Vector2i(0, 3)]

@onready var LAYER_FROM_TYPE: Dictionary[Flower.FlowerType, TileMapLayer] = {
	Flower.FlowerType.FLOWER_COLOR_1: $"TileMapLayer1",
	Flower.FlowerType.FLOWER_COLOR_2: $"TileMapLayer2",
	Flower.FlowerType.FLOWER_COLOR_3: $"TileMapLayer3"
}

const ATLAS_OFFSETS: Dictionary[Flower.FlowerType, Vector2i] = {
	Flower.FlowerType.FLOWER_COLOR_1: Vector2i(0, 0),
	Flower.FlowerType.FLOWER_COLOR_2: Vector2i(0, 4),
	Flower.FlowerType.FLOWER_COLOR_3: Vector2i(0, 8)
}

enum Dir {HORIZONTAL, VERTICAL}

const VECTOR_TO_DIRECTION: Dictionary[Vector2i, Dir] = {
	Vector2i(-1, 0): Dir.HORIZONTAL,
	Vector2i( 1, 0): Dir.HORIZONTAL,
	Vector2i( 0,-1): Dir.VERTICAL,
	Vector2i( 0, 1): Dir.VERTICAL
}

const ATLAS_COORDS_TO_DIRECTION: Dictionary[Vector2i, Dir] = {
	Vector2i(2, 0): Dir.HORIZONTAL,
	Vector2i(2, 4): Dir.HORIZONTAL,
	Vector2i(2, 8): Dir.HORIZONTAL,
	Vector2i(0, 2): Dir.VERTICAL,
	Vector2i(0, 6): Dir.VERTICAL,
	Vector2i(0,10): Dir.VERTICAL,
	
	Vector2i(3, 1): Dir.HORIZONTAL,
	Vector2i(3, 2): Dir.HORIZONTAL,
	Vector2i(3, 5): Dir.HORIZONTAL,
	Vector2i(3, 6): Dir.HORIZONTAL,
	Vector2i(3, 9): Dir.HORIZONTAL,
	Vector2i(3,10): Dir.HORIZONTAL,
	Vector2i(1, 3): Dir.VERTICAL,
	Vector2i(2, 3): Dir.VERTICAL,
	Vector2i(1, 7): Dir.VERTICAL,
	Vector2i(2, 7): Dir.VERTICAL,
	Vector2i(1,11): Dir.VERTICAL,
	Vector2i(2,11): Dir.VERTICAL,
}

func _ready() -> void:
	
	z_dimension = len(boards)
	boards.append(self)
	
	self.custom_minimum_size = Vector2.ONE * TILE_SIZE * board_dimensions_cells
	
	for x: int in range(board_dimensions_cells):
		for y: int in range(board_dimensions_cells):
			$BackgroundTiles.set_cell(Vector2i(x, y), 0, Vector2i(randi_range(0, 4), 13))


func create_flower_at_random_location(type: Flower.FlowerType) -> void:
	var attempts: int = 16
	var x: int
	var y: int
	while attempts:
		x = randi_range(0, board_dimensions_cells - 1)
		y = randi_range(0, board_dimensions_cells - 1)
		if is_empty_at_cell(Vector2i(x, y)):
			create_flower(x, y, type)
			return
		else:
			attempts -= 1
	# Couldn't find a safe place. The board is too full.
	# Will now replace a cell with a flower.
	if can_force_clear(Vector2i(x, y)):
		force_clear_cell(Vector2i(x, y), true, type)
		create_flower(x, y, type)

func create_obstacle_at_random_location() -> void:
	var x: int = randi_range(0, board_dimensions_cells - 1)
	var y: int = randi_range(0, board_dimensions_cells - 1)
	if is_empty_at_cell(Vector2i(x, y)):
		create_obstacle(x, y)

func create_flower(x_cell: int, y_cell: int, flower_type: Flower.FlowerType) -> void:
	var real_flower: Flower = PACKED_FLOWER.instantiate()
	$Flowers.add_child(real_flower)
	real_flower.position = $TileMapLayer1.map_to_local(Vector2i(x_cell, y_cell))
	real_flower.type = flower_type
	$"../..".flower_lists[flower_type].append(real_flower)
	real_flower.cell = Vector2i(x_cell, y_cell)
	LAYER_FROM_TYPE[flower_type].set_cell(Vector2i(x_cell, y_cell), 0, ATLAS_OFFSETS[flower_type])
	real_flower.start_particles()

func create_portal(x_cell: int, y_cell: int) -> Portal:
	var real_portal: Portal = PACKED_PORTAL.instantiate()
	$Portals.add_child(real_portal)
	real_portal.position = $TileMapLayer1.map_to_local(Vector2i(x_cell, y_cell))
	$TileMapLayer1.set_cell(Vector2i(x_cell, y_cell), 0, PORTAL_ATLAS_COORDS)
	$TileMapLayer2.set_cell(Vector2i(x_cell, y_cell), 0, PORTAL_ATLAS_COORDS)
	$TileMapLayer3.set_cell(Vector2i(x_cell, y_cell), 0, PORTAL_ATLAS_COORDS)
	real_portal.cell = Vector2i(x_cell, y_cell)
	return real_portal

func create_obstacle(x_cell: int, y_cell: int) -> void:
	var real_obstacle: Obstacle = PACKED_OBSTACLE.instantiate()
	$Obstacles.add_child(real_obstacle)
	real_obstacle.position = $TileMapLayer1.map_to_local(Vector2i(x_cell, y_cell))
	$TileMapLayer1.set_cell(Vector2i(x_cell, y_cell), 0, OBSTACLE_ATLAS_COORDS)
	$TileMapLayer2.set_cell(Vector2i(x_cell, y_cell), 0, OBSTACLE_ATLAS_COORDS)
	$TileMapLayer3.set_cell(Vector2i(x_cell, y_cell), 0, OBSTACLE_ATLAS_COORDS)
	real_obstacle.cell = Vector2i(x_cell, y_cell)
	

func _physics_process(_delta: float) -> void:
	if erase_mode:
		erase()
	else:
		draw()

func is_empty_at_cell(cell: Vector2i) -> bool:
	var l1: bool = ($TileMapLayer1.get_cell_atlas_coords(cell) == EMPTY_ATLAS_COORDS)
	var l2: bool = ($TileMapLayer2.get_cell_atlas_coords(cell) == EMPTY_ATLAS_COORDS)
	var l3: bool = ($TileMapLayer3.get_cell_atlas_coords(cell) == EMPTY_ATLAS_COORDS)
	return l1 and l2 and l3

func delete_portal(cell: Vector2i) -> void:
	for layer: TileMapLayer in LAYER_FROM_TYPE.values():
		layer.erase_cell(cell)

func delete_obstacle(cell: Vector2i) -> void:
	for layer: TileMapLayer in LAYER_FROM_TYPE.values():
		layer.erase_cell(cell)

## Return the type of a flower located at cell
func determine_flower_type(cell: Vector2i) -> Flower.FlowerType:
	var type: Flower.FlowerType
	for test_type: Flower.FlowerType in Flower.FLOWER_TYPES:
		if LAYER_FROM_TYPE[test_type].get_cell_atlas_coords(cell) == ATLAS_OFFSETS[test_type]:
			type = test_type
			break
	return type

## Count in how many directions is a flower connected
func count_flower_connections(cell: Vector2i) -> int:
	# Determine flower type
	var type: Flower.FlowerType = determine_flower_type(cell)
	var count: int = 0
	
	for direction: Vector2i in VECTOR_TO_ATLAS_INDEX.keys():
		if does_cell_have_connection(cell, type, direction):
			count += 1
	
	return count

#region dark magic

func can_force_clear(cell) -> bool:
	for type: Flower.FlowerType in Flower.FLOWER_TYPES:
		var atlascoords: Vector2i = LAYER_FROM_TYPE[type].get_cell_atlas_coords(cell)
		if atlascoords == PORTAL_ATLAS_COORDS: return false # Can't erase
		elif atlascoords == ATLAS_OFFSETS[type]: return false # Can't erase
		elif atlascoords == OBSTACLE_ATLAS_COORDS: return false # Can't erase
	return true

## Forces clears a cell, deleting vines in the process. Will not overwrite portals/flowers/obstacles
func force_clear_cell(cell: Vector2i, keep_vine_attachments: bool = false, keep_vine_type: Flower.FlowerType = Flower.FlowerType.FLOWER_COLOR_1) -> void:
	for type: Flower.FlowerType in Flower.FLOWER_TYPES:
		var atlascoords: Vector2i = LAYER_FROM_TYPE[type].get_cell_atlas_coords(cell)
		if atlascoords.y >= 4: atlascoords -= ATLAS_OFFSETS[type]
		if atlascoords == EMPTY_ATLAS_COORDS: continue # Don't need to erase
		elif ATLAS_COORDS_TO_ATLAS_INDEX.has(atlascoords):
			# Normal vine
			if type != keep_vine_type or not keep_vine_attachments:
				for direction: Vector2i in VECTOR_TO_ATLAS_INDEX.keys():
					if does_cell_have_connection(cell, type, direction):
						try_to_erase_path(cell, direction, type)
				LAYER_FROM_TYPE[type].erase_cell(cell)
			continue
		else:
			# Overpass!
			if type != keep_vine_type or not keep_vine_attachments:
				for direction: Vector2i in VECTOR_TO_ATLAS_INDEX.keys():
					try_to_erase_path(cell, direction, type)
				LAYER_FROM_TYPE[type].erase_cell(cell)
			continue

func remove_flower(cell: Vector2i) -> void:
	var type: Flower.FlowerType = determine_flower_type(cell)
	var replace_atlasindex: int = 0
	
	# Determine what cells this fower is connected to
	for direction: Vector2i in VECTOR_TO_ATLAS_INDEX.keys():
		if does_cell_have_connection(cell, type, direction):
			replace_atlasindex |= VECTOR_TO_ATLAS_INDEX[direction]
	
	var replace_atlascoords: Vector2i = ATLAS_INDEX_TO_ATLAS_COORDS[replace_atlasindex] + ATLAS_OFFSETS[type]
	
	LAYER_FROM_TYPE[type].set_cell(cell, 0, replace_atlascoords)

func is_portal_connected(cell: Vector2i) -> bool:
	assert($TileMapLayer1.get_cell_atlas_coords(cell) == PORTAL_ATLAS_COORDS)
	var portal1: Portal = get_portal_at_cell(cell)
	for type: Flower.FlowerType in Flower.FLOWER_TYPES:
		for direction: Vector2i in [Vector2i( 0,-1), Vector2i( 1, 0), Vector2i( 0, 1), Vector2i(-1, 0)]:
			if self == portal1.linked_portal.get_node(^"../.."):
				# Linked portal is on the same board.
				if portal1.linked_portal.cell == cell + direction:
					# Portal is next to its linked portal! Don't test does_cell_have_connection to avoid infinite loop!
					continue
			if does_cell_have_connection(cell, type, direction):
				var portal2: Portal = portal1.linked_portal
				if portal2.get_node(^"../..").does_cell_have_connection(portal2.cell, type, -direction):
					return true
	return false # Found no connections

func does_cell_have_connection(cell: Vector2i, type: Flower.FlowerType, direction: Vector2i) -> bool:
	var cell2: Vector2i = cell + direction
	var atlascoords2: Vector2i = LAYER_FROM_TYPE[type].get_cell_atlas_coords(cell2)
	match atlascoords2:
		EMPTY_ATLAS_COORDS:
			return false
		OBSTACLE_ATLAS_COORDS:
			return false
		FLOWER_ATLAS_COORDS: return true
		FLOWER_ATLAS_COORDS + ATLAS_OFFSETS[Flower.FlowerType.FLOWER_COLOR_2]: return true
		FLOWER_ATLAS_COORDS + ATLAS_OFFSETS[Flower.FlowerType.FLOWER_COLOR_3]: return true
		PORTAL_ATLAS_COORDS:
			var portal2: Portal = get_portal_at_cell(cell2).linked_portal
			return portal2.get_node(^"../..").does_cell_have_connection(portal2.cell, type, direction)
		_:
			# Branch
			atlascoords2 -= ATLAS_OFFSETS[type]
			if not atlascoords2 in ATLAS_COORDS_TO_ATLAS_INDEX.keys():
				# Overpass!
				return VECTOR_TO_DIRECTION[direction] == ATLAS_COORDS_TO_DIRECTION[atlascoords2]
			
			var atlasindex2: int = ATLAS_COORDS_TO_ATLAS_INDEX[atlascoords2]
			var testing_index: int = INVERT_ATLAS_INDEX[VECTOR_TO_ATLAS_INDEX[direction]]
			return bool(atlasindex2 & testing_index)

func erase() -> void:
	if is_drawing:
		if !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			is_drawing = false
			return
		var cell: Vector2i = $TileMapLayer1.local_to_map(get_local_mouse_position() / $TileMapLayer1.scale)
		if cell != drawing_cell:
			for type: Flower.FlowerType in Flower.FLOWER_TYPES:
				var layer: TileMapLayer = LAYER_FROM_TYPE[type]
				var atlascoords: Vector2i = layer.get_cell_atlas_coords(cell)
				if atlascoords == EMPTY_ATLAS_COORDS: continue # Empty square!
				if atlascoords == OBSTACLE_ATLAS_COORDS: continue # Obstacle
				atlascoords -= ATLAS_OFFSETS[type]
				
				for direction: Vector2i in VECTOR_TO_ATLAS_INDEX.keys():
					try_to_erase_path(cell, direction, type)
				
				if not atlascoords in [FLOWER_ATLAS_COORDS, PORTAL_ATLAS_COORDS]:
					layer.erase_cell(cell)
				
				if not atlascoords in DEAD_ENDS:
					$"../..".check_disconnected_regions(drawing_type)
	else:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var cell: Vector2i = $TileMapLayer1.local_to_map(get_local_mouse_position() / $TileMapLayer1.scale)
			if cell.x < 0 or cell.y < 0 or cell.x >= board_dimensions_cells or cell.y >= board_dimensions_cells:
				# Out of this board's bounds
				return
			is_drawing = true
			drawing_cell = Vector2i(-1, -1) # Set drawing cell (the previous cell the mouse was held over
			# ... to a nonsense value so that it thinks the player just moved the mouse as soon as they
			# .. start erasing.

## Tries to erase a path from cell to (cell+offset) in the given flower type
func try_to_erase_path(cell: Vector2i, offset: Vector2i, type: Flower.FlowerType) -> void:
	var layer: TileMapLayer = LAYER_FROM_TYPE[type]
	var atlascoords = layer.get_cell_atlas_coords(cell + offset)
	if atlascoords == EMPTY_ATLAS_COORDS: return
	if atlascoords == OBSTACLE_ATLAS_COORDS: return
	if atlascoords == PORTAL_ATLAS_COORDS:
		var portal1: Portal = get_portal_at_cell(cell + offset)
		var portal2: Portal = portal1.linked_portal
		var board2: Board = portal2.get_node(^"../..")
		
		if self == board2 and portal2.cell == cell: return # Stop infinite recursion
		
		board2.try_to_erase_path(portal2.cell, offset, type)
		return
	atlascoords -= ATLAS_OFFSETS[type]
	if not ATLAS_COORDS_TO_ATLAS_INDEX.has(atlascoords):
		#TODO FIX
		if atlascoords == FLOWER_ATLAS_COORDS: # Is a flower!
			return
		else: # Is an overpass! Erase it.
			var type_to_keep: Flower.FlowerType
			LAYER_FROM_TYPE[type].erase_cell(cell + offset)
			
			for test_type: Flower.FlowerType in Flower.FLOWER_TYPES:
				if LAYER_FROM_TYPE[test_type].get_cell_atlas_coords(cell + offset) != EMPTY_ATLAS_COORDS:
					type_to_keep = test_type
					break
			
			var other_atlascoords: Vector2i = LAYER_FROM_TYPE[type_to_keep].get_cell_atlas_coords(cell + offset)

			# Convert the other part of the overpass to a normal straight piece
			match ATLAS_COORDS_TO_DIRECTION[other_atlascoords]:
				Dir.HORIZONTAL:
					LAYER_FROM_TYPE[type_to_keep].set_cell(cell + offset, 0, Vector2i(2, 0) + ATLAS_OFFSETS[type_to_keep])
				Dir.VERTICAL:
					LAYER_FROM_TYPE[type_to_keep].set_cell(cell + offset, 0, Vector2i(0, 2) + ATLAS_OFFSETS[type_to_keep])
			
			#try_to_erase_path(cell + offset * 2, -offset, type)
			try_to_erase_path(cell + offset, offset, type)
			
			return
	var atlasindex: int = ATLAS_COORDS_TO_ATLAS_INDEX[atlascoords]
	var path = INVERT_ATLAS_INDEX[VECTOR_TO_ATLAS_INDEX[offset]]
	atlasindex &= ~path
	if not atlasindex:
		# Wasn't connected to anything else!
		layer.erase_cell(cell + offset)
		return
	atlascoords = ATLAS_INDEX_TO_ATLAS_COORDS[atlasindex]
	layer.set_cell(cell + offset, 0, atlascoords + ATLAS_OFFSETS[type])

static func get_cells_connected_to_cell_3d(cell: Vector3i, type: Flower.FlowerType) -> Array[Vector3i]:
	return boards[cell.z].get_cells_connected_to_cell(Vector2i(cell.x, cell.y), type)

func get_cell_connected_in_direction(cell: Vector2i, type: Flower.FlowerType, direction: Vector2i) -> Vector3i:
	if LAYER_FROM_TYPE[type].get_cell_atlas_coords(cell + direction) == PORTAL_ATLAS_COORDS:
		return check_through_portal_connection(get_portal_at_cell(cell + direction), direction, type)
	else:
		return Vector3i(cell.x + direction.x, cell.y + direction.y, z_dimension)

func get_cells_connected_to_cell(cell: Vector2i, type: Flower.FlowerType) -> Array[Vector3i]:
	var returns: Array[Vector3i] = []
	var layer: TileMapLayer = LAYER_FROM_TYPE[type]
	
	# Get atlas index
	var atlascoords: Vector2i = layer.get_cell_atlas_coords(cell)
	if atlascoords == EMPTY_ATLAS_COORDS: return []
	if atlascoords == OBSTACLE_ATLAS_COORDS: return []
	if atlascoords != PORTAL_ATLAS_COORDS:
		atlascoords -= ATLAS_OFFSETS[type]
	
	const CONNECTED_CELLS: Dictionary[Vector2i, Array] = {
		Vector2i( 0,-1): ## Cells that will connect to a flower south of them
			[FLOWER_ATLAS_COORDS, PORTAL_ATLAS_COORDS,
			Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 3), Vector2i(2, 3)], 
		Vector2i( 1, 0): ## Cells that will connect to a flower west of them
			[FLOWER_ATLAS_COORDS, PORTAL_ATLAS_COORDS,
			Vector2i(2, 0), Vector2i(3, 0), Vector2i(2, 1), Vector2i(2, 2), Vector2i(3, 1), Vector2i(3, 2)],
		Vector2i( 0, 1): ## Cells that will connect to a flower north of them
			[FLOWER_ATLAS_COORDS, PORTAL_ATLAS_COORDS,
			Vector2i(0, 2), Vector2i(0, 3), Vector2i(1, 2), Vector2i(2, 2), Vector2i(1, 3), Vector2i(2, 3)],
		Vector2i(-1, 0): ## Cells that will connect to a flower east of them
			[FLOWER_ATLAS_COORDS, PORTAL_ATLAS_COORDS,
			Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(3, 1), Vector2i(3, 2)] 
	}
	
	if atlascoords == FLOWER_ATLAS_COORDS:
		# Cell is a flower!
		for direction: Vector2i in CONNECTED_CELLS.keys():
			var atlascoords2: Vector2i = layer.get_cell_atlas_coords(cell + direction)
			if atlascoords2.y >= 4: atlascoords2 -= ATLAS_OFFSETS[type]
			if atlascoords2 in CONNECTED_CELLS[direction]:
				returns.append(get_cell_connected_in_direction(cell, type, direction))
	elif atlascoords == PORTAL_ATLAS_COORDS:
		return []
	elif ATLAS_COORDS_TO_ATLAS_INDEX.has(atlascoords):
		var atlasindex: int = ATLAS_COORDS_TO_ATLAS_INDEX[atlascoords]
		for direction: Vector2i in VECTOR_TO_ATLAS_INDEX.keys():
			if atlasindex & VECTOR_TO_ATLAS_INDEX[direction]:
				returns.append(get_cell_connected_in_direction(cell, type, direction))
	else:
		if ATLAS_COORDS_TO_DIRECTION[atlascoords] == Dir.HORIZONTAL:
			returns.append_array([	get_cell_connected_in_direction(cell, type, Vector2i(-1, 0)),
									get_cell_connected_in_direction(cell, type, Vector2i( 1, 0))])
		else:
			returns.append_array([	get_cell_connected_in_direction(cell, type, Vector2i( 0,-1)),
									get_cell_connected_in_direction(cell, type, Vector2i( 0, 1))])
	
	return returns

func draw() -> void:
	if is_drawing:
		# Stop drawing when mouse button is released
		if !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			is_drawing = false
			return
		
		
		var cell: Vector2i = $TileMapLayer1.local_to_map(get_local_mouse_position() / $TileMapLayer1.scale)
		if cell == drawing_cell: return
		
		if not can_draw_at(cell):
			# Can't draw 
			is_drawing = false
			return
			
		if not (cell - drawing_cell in VECTOR_TO_ATLAS_INDEX.keys()):
			# Didn't move orthogonally. Do nothing and stop drawing
			is_drawing = false
			return
		
		draw_cell(drawing_cell, cell, cell - drawing_cell)
		drawing_cell = cell
	else:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var cell: Vector2i = $TileMapLayer1.local_to_map(get_local_mouse_position() / $TileMapLayer1.scale)
			if not is_in_bounds(cell): return
			# Test to see if the player is clicking on a drawable cell
			if $TileMapLayer1.get_cell_atlas_coords(cell) in DRAWABLE_ATLAS_CELLS_1:
				is_drawing = true
				drawing_type = Flower.FlowerType.FLOWER_COLOR_1
				drawing_cell = cell
			elif $TileMapLayer2.get_cell_atlas_coords(cell) in DRAWABLE_ATLAS_CELLS_2:
				is_drawing = true
				drawing_type = Flower.FlowerType.FLOWER_COLOR_2
				drawing_cell = cell
			elif $TileMapLayer3.get_cell_atlas_coords(cell) in DRAWABLE_ATLAS_CELLS_3:
				is_drawing = true
				drawing_type = Flower.FlowerType.FLOWER_COLOR_3
				drawing_cell = cell

func is_in_bounds(cell: Vector2i) -> bool:
	return (cell.x >= 0) and (cell.y >= 0) and (cell.x < board_dimensions_cells) and (cell.y < board_dimensions_cells)

func can_draw_at(cell: Vector2i) -> bool:
	if not is_in_bounds(cell): return false # out of bounds
	
	if $TileMapLayer1.get_cell_atlas_coords(cell) == OBSTACLE_ATLAS_COORDS: return false
	
	if $TileMapLayer1.get_cell_atlas_coords(cell) == PORTAL_ATLAS_COORDS: return true
	
	if $TileMapLayer1.get_cell_atlas_coords(cell) in STRAIGHT_ATLAS_CELLS and drawing_type != Flower.FlowerType.FLOWER_COLOR_1: return true
	if $TileMapLayer2.get_cell_atlas_coords(cell) in STRAIGHT_ATLAS_CELLS and drawing_type != Flower.FlowerType.FLOWER_COLOR_2: return true
	if $TileMapLayer3.get_cell_atlas_coords(cell) in STRAIGHT_ATLAS_CELLS and drawing_type != Flower.FlowerType.FLOWER_COLOR_3: return true
	
	if $TileMapLayer1.get_cell_atlas_coords(cell) != EMPTY_ATLAS_COORDS:
		if drawing_type != Flower.FlowerType.FLOWER_COLOR_1 or not $TileMapLayer1.get_cell_atlas_coords(cell) in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(3, 0), Vector2i(0, 1), Vector2i(0, 3)]:
			return false # already something here!
	if $TileMapLayer2.get_cell_atlas_coords(cell) != EMPTY_ATLAS_COORDS:
		if drawing_type != Flower.FlowerType.FLOWER_COLOR_2 or not $TileMapLayer2.get_cell_atlas_coords(cell) in [Vector2i(0, 4), Vector2i(1, 4), Vector2i(3, 4), Vector2i(0, 5), Vector2i(0, 7)]:
			return false # already something here!
	if $TileMapLayer3.get_cell_atlas_coords(cell) != EMPTY_ATLAS_COORDS:
		if drawing_type != Flower.FlowerType.FLOWER_COLOR_3 or not $TileMapLayer3.get_cell_atlas_coords(cell) in [Vector2i(0, 8), Vector2i(1, 8), Vector2i(3, 8), Vector2i(0, 9), Vector2i(0,11)]:
			return false # already something here!
	return true

func get_portal_at_cell(cell: Vector2i) -> Portal:
	for portal: Portal in $Portals.get_children():
		if $TileMapLayer1.local_to_map(portal.position) == cell:
			return portal
	
	# No portals found
	return null

func get_flower_at_cell(cell: Vector2i) -> Flower:
	for flower: Flower in $Flowers.get_children():
		if $TileMapLayer1.local_to_map(flower.position) == cell:
			return flower
	
	# No flowers found
	return null

static func get_flowers_connected_to_cell(cell: Vector3i, type: Flower.FlowerType) -> Array[Flower]:
	var returns: Array[Flower] = []
	
	var found: Array[Vector3i] = []
	var newfound: Array[Vector3i] = [cell]
	
	while len(newfound):
		if boards[newfound[0].z].LAYER_FROM_TYPE[type].get_cell_atlas_coords(Vector2i(newfound[0].x, newfound[0].y)) in ATLAS_OFFSETS.values():
			returns.append(boards[newfound[0].z].get_flower_at_cell(Vector2i(newfound[0].x, newfound[0].y)))
		
		var adjacent: Array[Vector3i] = get_cells_connected_to_cell_3d(newfound[0], type)
		adjacent.erase(Vector3i(-1, -1, -1))
		
		for adjacent_cell: Vector3i in adjacent:
			if not (adjacent_cell in newfound or adjacent_cell in found):
				newfound.append(adjacent_cell)
		
		found.append(newfound[0])
		newfound.erase(newfound[0])
	
	
	return returns

func check_through_portal_connection(portal: Portal, direction: Vector2i, type: Flower.FlowerType) -> Vector3i:
	const NULL_RETURN := Vector3i(-1, -1, -1)
	
	var portal2: Portal = portal.linked_portal
	var board2: Board = portal2.get_node(^"../..")
	var layer2: TileMapLayer = board2.LAYER_FROM_TYPE[type]
	
	var atlascoords2: Vector2i = layer2.get_cell_atlas_coords(portal2.cell + direction)
	
	if atlascoords2 == EMPTY_ATLAS_COORDS or atlascoords2 == OBSTACLE_ATLAS_COORDS:
		return NULL_RETURN
	elif atlascoords2 == PORTAL_ATLAS_COORDS:
		return check_through_portal_connection(board2.get_portal_at_cell(portal2.cell + direction), direction, type)
	else:
		atlascoords2 -= ATLAS_OFFSETS[type]
		if atlascoords2 == FLOWER_ATLAS_COORDS:
			# Flower
			return Vector3i(portal2.cell.x + direction.x, portal2.cell.y + direction.y, board2.z_dimension)
		elif ATLAS_COORDS_TO_ATLAS_INDEX.has(atlascoords2):
			# Normal cell!
			var index_to_test: int = INVERT_ATLAS_INDEX[VECTOR_TO_ATLAS_INDEX[direction]]
			if index_to_test & ATLAS_COORDS_TO_ATLAS_INDEX[atlascoords2]:
				return Vector3i(portal2.cell.x + direction.x, portal2.cell.y + direction.y, board2.z_dimension)
			else:
				return NULL_RETURN
		else:
			# Overpass
			if direction.x == 0:
				# Vertical direction
				if atlascoords2 in OVERPASS_ATLAS_CELLS_VERTICAL:
					return Vector3i(portal2.cell.x + direction.x, portal2.cell.y + direction.y, board2.z_dimension)
				else:
					return NULL_RETURN
			else:
				# Horizontal direction
				if atlascoords2 in OVERPASS_ATLAS_CELLS_HORIZONTAL:
					return Vector3i(portal2.cell.x + direction.x, portal2.cell.y + direction.y, board2.z_dimension)
				else:
					return NULL_RETURN

func can_draw_through_portal(cell: Vector2i, direction: Vector2i) -> bool:
	var portal1: Portal = get_portal_at_cell(cell)
	var portal2: Portal = portal1.linked_portal
	var cell2: Vector2i = portal2.cell + direction;
	var other_board: Board = portal2.get_node(^"../..")
	if not other_board.can_draw_at(cell2): return false
	var atlascoords: Vector2i = LAYER_FROM_TYPE[drawing_type].get_cell_atlas_coords(cell2)
	if atlascoords == PORTAL_ATLAS_COORDS:
		return other_board.can_draw_through_portal(cell2, direction)
	return true

func can_make_overpass(cell: Vector2i, direction: Vector2i) -> bool:
	var cell2: Vector2i = cell + direction;
	if not can_draw_at(cell2): return false
	for test_type: Flower.FlowerType in Flower.FLOWER_TYPES:
		var atlascoords: Vector2i = LAYER_FROM_TYPE[test_type].get_cell_atlas_coords(cell2)
		if atlascoords == EMPTY_ATLAS_COORDS: continue
		if atlascoords.y >= 4: atlascoords -= ATLAS_OFFSETS[test_type]
		if atlascoords in DEAD_ENDS:
			return test_type == drawing_type
		elif atlascoords in STRAIGHT_ATLAS_CELLS:
			if VECTOR_TO_DIRECTION[direction] == ATLAS_COORDS_TO_DIRECTION[atlascoords]: return false
			return can_make_overpass(cell2, direction)
		elif atlascoords == PORTAL_ATLAS_COORDS:
			var portal: Portal = get_portal_at_cell(cell2).linked_portal
			var other_board: Board = portal.get_node(^"../..")
			return other_board.can_make_overpass(portal.cell + direction, direction)
	return true

func draw_cell(cell1: Vector2i, cell2: Vector2i, direction: Vector2i) -> void:
	# Cell 1: The cell the player is drawing FROM
	# Cell 2: The cell the player is drawing TO
	var layer: TileMapLayer = LAYER_FROM_TYPE[drawing_type]
	var making_overpass: bool = false
	var should_recheck_connected_flowers: bool = false
	
	for test_layer: TileMapLayer in LAYER_FROM_TYPE.values():
		if test_layer == layer: continue
		if test_layer.get_cell_atlas_coords(cell2) in STRAIGHT_ATLAS_CELLS:
			making_overpass = true
			break
	
	if is_in_bounds(cell2):
		var atlascoords2: Vector2i = layer.get_cell_atlas_coords(cell2)
		
		if making_overpass:
			if can_make_overpass(cell2, direction):
				convert_to_overpass(cell2)
				draw_cell(Vector2i(-1, -1), cell2 + direction, direction)
			else:
				is_drawing = false
				return
		elif atlascoords2 == EMPTY_ATLAS_COORDS:
			var atlasindex2_add = VECTOR_TO_ATLAS_INDEX[-direction]
			var atlascoords2_add: Vector2i = ATLAS_INDEX_TO_ATLAS_COORDS[atlasindex2_add]
			layer.set_cell(cell2, 0, atlascoords2_add + ATLAS_OFFSETS[drawing_type])
		elif atlascoords2 == ATLAS_OFFSETS[drawing_type]:
			is_drawing = false
			should_recheck_connected_flowers = true
		elif atlascoords2 == PORTAL_ATLAS_COORDS:
			if can_draw_through_portal(cell2, direction):
				var portal: Portal = get_portal_at_cell(cell2).linked_portal
				var other_board: Board = portal.get_node(^"../..")
				other_board.draw_cell(Vector2i(-1, -1), portal.cell + direction, direction)
				is_drawing = false
			else:
				is_drawing = false
				return
		elif atlascoords2 == OBSTACLE_ATLAS_COORDS:
			is_drawing = false
			return
		elif atlascoords2 - ATLAS_OFFSETS[drawing_type] in DEAD_ENDS:
			var atlasindex2_add = VECTOR_TO_ATLAS_INDEX[-direction]
			var atlasindex2 = ATLAS_COORDS_TO_ATLAS_INDEX[atlascoords2 - ATLAS_OFFSETS[drawing_type]]
			var altasindex2_new = atlasindex2 | atlasindex2_add
			var atlascoords2_new: Vector2i = ATLAS_INDEX_TO_ATLAS_COORDS[altasindex2_new]
			layer.set_cell(cell2, 0, atlascoords2_new + ATLAS_OFFSETS[drawing_type])
			is_drawing = false
			should_recheck_connected_flowers = true
	
	
	if is_in_bounds(cell1):
		var atlasindex1_add: int = VECTOR_TO_ATLAS_INDEX[direction]
		
		# Set previous cell's atlas
		var atlascoords1 = layer.get_cell_atlas_coords(cell1) - ATLAS_OFFSETS[drawing_type]
		if atlascoords1 in DEAD_ENDS:
			# Update previous cell
			var atlasindex1 = ATLAS_COORDS_TO_ATLAS_INDEX[atlascoords1]
			var atlasindex1_new = atlasindex1 | atlasindex1_add
			var atlascoords1_new = ATLAS_INDEX_TO_ATLAS_COORDS[atlasindex1_new]
			layer.set_cell(cell1, 0, atlascoords1_new + ATLAS_OFFSETS[drawing_type])
	
	if should_recheck_connected_flowers:
		$"../..".check_disconnected_regions(drawing_type)

func convert_to_overpass(cell: Vector2i) -> void:
	# Get the FlowerType of the existing vine
	var bottom_type: Flower.FlowerType
	var bottom_direction: Dir
	var bottom_atlascoords: Vector2i
	for type: Flower.FlowerType in Flower.FLOWER_TYPES:
		bottom_atlascoords = LAYER_FROM_TYPE[type].get_cell_atlas_coords(cell)
		if bottom_atlascoords in STRAIGHT_ATLAS_CELLS:
			bottom_type = type
			bottom_direction = ATLAS_COORDS_TO_DIRECTION[bottom_atlascoords]
			break
		else:
			assert(LAYER_FROM_TYPE[type].get_cell_atlas_coords(cell) == EMPTY_ATLAS_COORDS)
	
	if bottom_direction == Dir.HORIZONTAL:
		LAYER_FROM_TYPE[bottom_type].set_cell(cell, 0, bottom_atlascoords + Vector2i(1, 2))
		LAYER_FROM_TYPE[drawing_type].set_cell(cell, 0, ATLAS_OFFSETS[drawing_type] + Vector2i(2, 3))
	else:
		LAYER_FROM_TYPE[bottom_type].set_cell(cell, 0, bottom_atlascoords + Vector2i(1, 1))
		LAYER_FROM_TYPE[drawing_type].set_cell(cell, 0, ATLAS_OFFSETS[drawing_type] + Vector2i(3, 1))

#endregion
