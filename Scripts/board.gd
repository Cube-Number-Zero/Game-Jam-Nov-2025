class_name Board extends Control
## A single board with a tilemap inside. Several of these will be linked together with portals

const PACKED_FLOWER: PackedScene = preload("res://Scenes/flower.tscn")
const PACKED_PORTAL: PackedScene = preload("res://Scenes/portal.tscn")

const TILE_SIZE: int = 26 ## The height/width of tiles, in pixels
const BOARD_DIMENSIONS_CELLS: int = 12 ## The width of the board, in cells

var is_drawing: bool = false ## Whether or not the player is currently drawing
static var drawing_type: Flower.FlowerType
var drawing_cell: Vector2i


static var boards: Array[Board] = []
var z_dimension: int

static var erase_mode: bool = false

const EMPTY_ATLAS_COORDS := Vector2i(-1, -1)
const FLOWER_ATLAS_COORDS := Vector2i(0, 0)
const PORTAL_ATLAS_COORDS := Vector2i(4, 0)

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

@onready var flowertype: Dictionary[Flower.FlowerType, TileMapLayer] = {
	Flower.FlowerType.FLOWER_COLOR_1: $"TileMapLayer1",
	Flower.FlowerType.FLOWER_COLOR_2: $"TileMapLayer2",
	Flower.FlowerType.FLOWER_COLOR_3: $"TileMapLayer3"
}

const ATLAS_OFFSETS: Dictionary[Flower.FlowerType, Vector2i] = {
	Flower.FlowerType.FLOWER_COLOR_1: Vector2i(0, 0),
	Flower.FlowerType.FLOWER_COLOR_2: Vector2i(0, 4),
	Flower.FlowerType.FLOWER_COLOR_3: Vector2i(0, 8)
}

func _ready() -> void:
	
	z_dimension = len(boards)
	boards.append(self)
	
	self.custom_minimum_size = Vector2.ONE * TILE_SIZE * BOARD_DIMENSIONS_CELLS
	
	for x: int in range(BOARD_DIMENSIONS_CELLS):
		for y: int in range(BOARD_DIMENSIONS_CELLS):
			$BackgroundTiles.set_cell(Vector2i(x, y), 0, Vector2i(randi_range(0, 4), 13))
	
	# Create three random flowers (for testing purposes)
	create_flower(	randi_range(0, BOARD_DIMENSIONS_CELLS - 1),
					randi_range(0, BOARD_DIMENSIONS_CELLS - 1),
					Flower.FlowerType.FLOWER_COLOR_1)
	create_flower(	randi_range(0, BOARD_DIMENSIONS_CELLS - 1),
					randi_range(0, BOARD_DIMENSIONS_CELLS - 1),
					Flower.FlowerType.FLOWER_COLOR_2)
	create_flower(	randi_range(0, BOARD_DIMENSIONS_CELLS - 1),
					randi_range(0, BOARD_DIMENSIONS_CELLS - 1),
					Flower.FlowerType.FLOWER_COLOR_3)

func create_flower(x_cell: int, y_cell: int, flower_type: Flower.FlowerType) -> void:
	var real_flower: Flower = PACKED_FLOWER.instantiate()
	$Flowers.add_child(real_flower)
	real_flower.position = $TileMapLayer1.map_to_local(Vector2i(x_cell, y_cell))
	real_flower.type = flower_type
	$"../..".flower_lists[flower_type].append(real_flower)
	real_flower.cell = Vector2i(x_cell, y_cell)
	flowertype[flower_type].set_cell(Vector2i(x_cell, y_cell), 0, ATLAS_OFFSETS[flower_type])
	$"../..".check_disconnected_regions(flower_type)

func create_portal(x_cell: int, y_cell: int) -> Portal:
	var real_portal: Portal = PACKED_PORTAL.instantiate()
	$Portals.add_child(real_portal)
	real_portal.position = $TileMapLayer1.map_to_local(Vector2i(x_cell, y_cell))
	$TileMapLayer1.set_cell(Vector2i(x_cell, y_cell), 0, PORTAL_ATLAS_COORDS)
	$TileMapLayer2.set_cell(Vector2i(x_cell, y_cell), 0, PORTAL_ATLAS_COORDS)
	$TileMapLayer3.set_cell(Vector2i(x_cell, y_cell), 0, PORTAL_ATLAS_COORDS)
	real_portal.cell = Vector2i(x_cell, y_cell)
	$"../..".check_all_disconnected_regions()
	return real_portal

func _physics_process(_delta: float) -> void:
	if erase_mode:
		erase()
	else:
		draw()

#region black magic

func erase() -> void:
	if is_drawing:
		if !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			is_drawing = false
			return
		var cell: Vector2i = $TileMapLayer1.local_to_map(get_local_mouse_position() / $TileMapLayer1.scale)
		if cell != drawing_cell:
			for type: Flower.FlowerType in [Flower.FlowerType.FLOWER_COLOR_1, Flower.FlowerType.FLOWER_COLOR_2, Flower.FlowerType.FLOWER_COLOR_3]:
				var layer: TileMapLayer = flowertype[type]
				var atlascoords: Vector2i = layer.get_cell_atlas_coords(cell)
				if atlascoords == EMPTY_ATLAS_COORDS: continue # Empty square!
				atlascoords -= ATLAS_OFFSETS[type]
				
				try_to_erase_path(cell, Vector2i( 0,-1), type)
				try_to_erase_path(cell, Vector2i( 1, 0), type)
				try_to_erase_path(cell, Vector2i( 0, 1), type)
				try_to_erase_path(cell, Vector2i(-1, 0), type)
				
				if not atlascoords in [FLOWER_ATLAS_COORDS, PORTAL_ATLAS_COORDS]:
					layer.erase_cell(cell)
	else:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var cell: Vector2i = $TileMapLayer1.local_to_map(get_local_mouse_position() / $TileMapLayer1.scale)
			if cell.x < 0 or cell.y < 0 or cell.x >= BOARD_DIMENSIONS_CELLS or cell.y >= BOARD_DIMENSIONS_CELLS:
				# Out of this board's bounds
				return
			is_drawing = true
			drawing_cell = Vector2i(-1, -1)

## Tries to erase a path from cell to (cell+offset) in the given flower type
func try_to_erase_path(cell: Vector2i, offset: Vector2i, type: Flower.FlowerType) -> void:
	var layer: TileMapLayer = flowertype[type]
	var atlascoords = layer.get_cell_atlas_coords(cell + offset)
	if atlascoords == EMPTY_ATLAS_COORDS: return
	atlascoords -= ATLAS_OFFSETS[type]
	if not ATLAS_COORDS_TO_ATLAS_INDEX.has(atlascoords):
		if atlascoords == FLOWER_ATLAS_COORDS:
			# Is a flower!
			pass
		elif atlascoords == PORTAL_ATLAS_COORDS:
			# Is a portal!
			pass
		else:
			# Is an overpass! Erase it.
			$TileMapLayer1.erase_cell(cell + offset)
			$TileMapLayer2.erase_cell(cell + offset)
			$TileMapLayer3.erase_cell(cell + offset)
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

static func get_cells_connected_to_cell_3d(cell: Vector3i) -> Array[Vector3i]:
	return boards[cell.z].get_cells_connected_to_cell(Vector2i(cell.x, cell.y))

func get_cells_connected_to_cell(cell: Vector2i) -> Array[Vector3i]:
	var returns: Array[Vector3i] = []
	for type: Flower.FlowerType in [Flower.FlowerType.FLOWER_COLOR_1, Flower.FlowerType.FLOWER_COLOR_2, Flower.FlowerType.FLOWER_COLOR_3]:
		var layer: TileMapLayer = flowertype[drawing_type]
		
		# Get atlas index
		var atlascoords: Vector2i = layer.get_cell_atlas_coords(cell)
		if atlascoords == EMPTY_ATLAS_COORDS:
			continue # Empty square!
		if atlascoords != PORTAL_ATLAS_COORDS:
			atlascoords -= ATLAS_OFFSETS[type]
		
		const CONNECTED_ABOVE: Array[Vector2i] = [
			FLOWER_ATLAS_COORDS, PORTAL_ATLAS_COORDS, Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 3), Vector2i(2, 3)
		] ## Cells that will connect to a flower south of them
		const CONNECTED_RIGHT: Array[Vector2i] = [
			FLOWER_ATLAS_COORDS, PORTAL_ATLAS_COORDS, Vector2i(2, 0), Vector2i(3, 0), Vector2i(2, 1), Vector2i(2, 2), Vector2i(3, 1), Vector2i(3, 2)
		] ## Cells that will connect to a flower south of them
		const CONNECTED_BELOW: Array[Vector2i] = [
			FLOWER_ATLAS_COORDS, PORTAL_ATLAS_COORDS, Vector2i(0, 2), Vector2i(0, 3), Vector2i(1, 2), Vector2i(2, 2), Vector2i(1, 3), Vector2i(2, 3)
		] ## Cells that will connect to a flower south of them
		const CONNECTED_LEFT: Array[Vector2i] = [
			FLOWER_ATLAS_COORDS, PORTAL_ATLAS_COORDS, Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(3, 1), Vector2i(3, 2)
		] ## Cells that will connect to a flower south of them
		
		if atlascoords == FLOWER_ATLAS_COORDS:
			# Cell is a flower!
			if layer.get_cell_atlas_coords(cell + Vector2i( 0,-1)) - ATLAS_OFFSETS[type] in CONNECTED_ABOVE:
				if flowertype[type].get_cell_atlas_coords(cell + Vector2i( 0,-1)) == PORTAL_ATLAS_COORDS:
					returns.append(check_through_portal_connection(get_portal_at_cell(cell + Vector2i( 0,-1)), Vector2i( 0,-1), type))
				else:
					returns.append(Vector3i(cell.x, cell.y - 1, z_dimension))
			if layer.get_cell_atlas_coords(cell + Vector2i( 1, 0)) - ATLAS_OFFSETS[type] in CONNECTED_RIGHT:
				if flowertype[type].get_cell_atlas_coords(cell + Vector2i( 1, 0)) == PORTAL_ATLAS_COORDS:
					returns.append(check_through_portal_connection(get_portal_at_cell(cell + Vector2i( 1, 0)), Vector2i( 1, 0), type))
				else:
					returns.append(Vector3i(cell.x + 1, cell.y, z_dimension))
			if layer.get_cell_atlas_coords(cell + Vector2i( 0, 1)) - ATLAS_OFFSETS[type] in CONNECTED_BELOW:
				if flowertype[type].get_cell_atlas_coords(cell + Vector2i( 0, 1)) == PORTAL_ATLAS_COORDS:
					returns.append(check_through_portal_connection(get_portal_at_cell(cell + Vector2i( 0, 1)), Vector2i( 0, 1), type))
				else:
					returns.append(Vector3i(cell.x, cell.y + 1, z_dimension))
			if layer.get_cell_atlas_coords(cell + Vector2i(-1, 0)) - ATLAS_OFFSETS[type] in CONNECTED_LEFT:
				if flowertype[type].get_cell_atlas_coords(cell + Vector2i(-1, 0)) == PORTAL_ATLAS_COORDS:
					returns.append(check_through_portal_connection(get_portal_at_cell(cell + Vector2i(-1, 0)), Vector2i(-1, 0), type))
				else:
					returns.append(Vector3i(cell.x - 1, cell.y, z_dimension))
		elif atlascoords == PORTAL_ATLAS_COORDS:
			return []
		elif ATLAS_COORDS_TO_ATLAS_INDEX.has(atlascoords):
			var atlasindex: int = ATLAS_COORDS_TO_ATLAS_INDEX[atlascoords]
			if atlasindex & 0x1:
				if flowertype[type].get_cell_atlas_coords(cell + Vector2i( 0,-1)) == PORTAL_ATLAS_COORDS:
					returns.append(check_through_portal_connection(get_portal_at_cell(cell + Vector2i( 0,-1)), Vector2i( 0,-1), type))
				else:
					returns.append(Vector3i(cell.x, cell.y - 1, z_dimension))
			if atlasindex & 0x2:
				if flowertype[type].get_cell_atlas_coords(cell + Vector2i( 1, 0)) == PORTAL_ATLAS_COORDS:
					returns.append(check_through_portal_connection(get_portal_at_cell(cell + Vector2i( 1, 0)), Vector2i( 1, 0), type))
				else:
					returns.append(Vector3i(cell.x + 1, cell.y, z_dimension))
			if atlasindex & 0x4:
				if flowertype[type].get_cell_atlas_coords(cell + Vector2i( 0, 1)) == PORTAL_ATLAS_COORDS:
					returns.append(check_through_portal_connection(get_portal_at_cell(cell + Vector2i( 0, 1)), Vector2i( 0, 1), type))
				else:
					returns.append(Vector3i(cell.x, cell.y + 1, z_dimension))
			if atlasindex & 0x8:
				if flowertype[type].get_cell_atlas_coords(cell + Vector2i(-1, 0)) == PORTAL_ATLAS_COORDS:
					returns.append(check_through_portal_connection(get_portal_at_cell(cell + Vector2i(-1, 0)), Vector2i(-1, 0), type))
				else:
					returns.append(Vector3i(cell.x - 1, cell.y, z_dimension))
		else:
			#Overpass!
			pass
	
	return returns

func draw() -> void:
	if is_drawing:
		# Stop drawing when mouse button is released
		if !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			is_drawing = false
			return
		
		
		var cell: Vector2i = $TileMapLayer1.local_to_map(get_local_mouse_position() / $TileMapLayer1.scale)
		if cell != drawing_cell:
			if can_draw_at(cell):
				if cell - drawing_cell in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]:
					var layer: TileMapLayer = flowertype[drawing_type]
					var atlasindex: int = VECTOR_TO_ATLAS_INDEX[cell - drawing_cell]
					var atlascoords: Vector2i = ATLAS_INDEX_TO_ATLAS_COORDS[INVERT_ATLAS_INDEX[atlasindex]]
					
					# Set previous cell's atlas
					var previous_atlas_coords = layer.get_cell_atlas_coords(drawing_cell) - ATLAS_OFFSETS[drawing_type]
					
					if ATLAS_COORDS_TO_ATLAS_INDEX.has(previous_atlas_coords):
						# Update previous cell
						var previous_atlas_index = ATLAS_COORDS_TO_ATLAS_INDEX[previous_atlas_coords]
						var new_atlas_index = previous_atlas_index ^ atlasindex
						if ATLAS_INDEX_TO_ATLAS_COORDS.has(new_atlas_index):
							var new_atlas_coords = ATLAS_INDEX_TO_ATLAS_COORDS[new_atlas_index]
							layer.set_cell(drawing_cell, 0, new_atlas_coords + ATLAS_OFFSETS[drawing_type])
					
					const DEAD_ENDS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(3, 0), Vector2i(0, 1), Vector2i(0, 3)]
					
					if layer.get_cell_atlas_coords(cell) - ATLAS_OFFSETS[drawing_type] in DEAD_ENDS:
						# cell is already a dead end, so connect them and finish drawing
						atlasindex = INVERT_ATLAS_INDEX[atlasindex] # i don't know why i need to do this
						atlasindex |= ATLAS_COORDS_TO_ATLAS_INDEX[layer.get_cell_atlas_coords(cell) - ATLAS_OFFSETS[drawing_type]]
						atlascoords = ATLAS_INDEX_TO_ATLAS_COORDS[atlasindex]
						is_drawing = false
					
					if layer.get_cell_atlas_coords(cell) in [ATLAS_OFFSETS[drawing_type], PORTAL_ATLAS_COORDS]:
						# SPECIAL CASE: Was a flower or portal!
						if layer.get_cell_atlas_coords(cell) == PORTAL_ATLAS_COORDS:
							# Draw through a portal!!!!!
							draw_through_portal(get_portal_at_cell(cell), cell - drawing_cell)
					else:
						layer.set_cell(cell, 0, atlascoords + ATLAS_OFFSETS[drawing_type])
					drawing_cell = cell
				else:
					# Didn't move orthogonally. Do nothing and stop drawing
					is_drawing = false
			else:
				# This cell can't be drawn on. Do nothing and stop drawing
				is_drawing = false
	else:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var cell: Vector2i = $TileMapLayer1.local_to_map(get_local_mouse_position() / $TileMapLayer1.scale)
			if cell.x < 0 or cell.y < 0 or cell.x >= BOARD_DIMENSIONS_CELLS or cell.y >= BOARD_DIMENSIONS_CELLS:
				# Out of this board's bounds
				return
			# Test to see if the player is clicking on a drawable cell
			if $TileMapLayer1.get_cell_atlas_coords(cell) in DRAWABLE_ATLAS_CELLS_1:
				is_drawing = true
				drawing_type = Flower.FlowerType.FLOWER_COLOR_1
				drawing_cell = cell
			if $TileMapLayer2.get_cell_atlas_coords(cell) in DRAWABLE_ATLAS_CELLS_2:
				is_drawing = true
				drawing_type = Flower.FlowerType.FLOWER_COLOR_2
				drawing_cell = cell
			if $TileMapLayer3.get_cell_atlas_coords(cell) in DRAWABLE_ATLAS_CELLS_3:
				is_drawing = true
				drawing_type = Flower.FlowerType.FLOWER_COLOR_3
				drawing_cell = cell

func draw_through_portal(portal: Portal, direction: Vector2i) -> void:
	is_drawing = false
	var portal2: Portal = portal.linked_portal
	var board2: Board = portal2.get_node(^"../..")
	
	# Check if new cell can be drawn at
	if not board2.can_draw_at(portal2.cell + direction):
		return
	
	var tilelayer2: TileMapLayer = board2.flowertype[drawing_type]
	var atlascoords2: Vector2i = tilelayer2.get_cell_atlas_coords(portal2.cell + direction)
	match atlascoords2:
		EMPTY_ATLAS_COORDS:
			var atlasindex: int = INVERT_ATLAS_INDEX[VECTOR_TO_ATLAS_INDEX[direction]]
			var atlascoords: Vector2i = ATLAS_INDEX_TO_ATLAS_COORDS[atlasindex] + ATLAS_OFFSETS[drawing_type]
			tilelayer2.set_cell(portal2.cell + direction, 0, atlascoords)
		PORTAL_ATLAS_COORDS:
			if get_portal_at_cell(portal2.cell + direction) == portal:
				return # STOP INFINITE LOOP
			else:
				draw_through_portal(board2.get_portal_at_cell(portal2.cell + direction), direction)
		FLOWER_ATLAS_COORDS:
			#Don't need to do anything.
			return
		_:
			var atlasindex: int = INVERT_ATLAS_INDEX[VECTOR_TO_ATLAS_INDEX[direction]]
			atlasindex |= ATLAS_COORDS_TO_ATLAS_INDEX[atlascoords2 - ATLAS_OFFSETS[drawing_type]]
			var atlascoords: Vector2i = ATLAS_INDEX_TO_ATLAS_COORDS[atlasindex] + ATLAS_OFFSETS[drawing_type]
			tilelayer2.set_cell(portal2.cell + direction, 0, atlascoords)
			
	
	#tilelayer2.set_cell(portal2.cell + cell - drawing_cell, 0, FLOWER_ATLAS_COORDS + atlas_offsets[drawing_type])

func can_draw_at(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= BOARD_DIMENSIONS_CELLS or cell.y >= BOARD_DIMENSIONS_CELLS:
		return false # out of bounds
	
	if $TileMapLayer1.get_cell_atlas_coords(cell) != PORTAL_ATLAS_COORDS:
		if $TileMapLayer1.get_cell_atlas_coords(cell) != EMPTY_ATLAS_COORDS:
			if drawing_type != Flower.FlowerType.FLOWER_COLOR_1 or not $TileMapLayer1.get_cell_atlas_coords(cell) in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(3, 0), Vector2i(0, 1), Vector2i(0, 3)]:
				return false # already something here!
		if $TileMapLayer2.get_cell_atlas_coords(cell) != EMPTY_ATLAS_COORDS:
			if drawing_type != Flower.FlowerType.FLOWER_COLOR_2 or not $TileMapLayer2.get_cell_atlas_coords(cell) in [Vector2i(0, 4), Vector2i(1, 4), Vector2i(3, 4), Vector2i(0, 5), Vector2i(0, 8)]:
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
	
	# No portals found
	return null

static func get_flowers_connected_to_cell(cell: Vector3i, type: Flower.FlowerType) -> Array[Flower]:
	var returns: Array[Flower] = []
	
	var found: Array[Vector3i] = []
	var newfound: Array[Vector3i] = [cell]
	
	while len(newfound):
		if boards[newfound[0].z].flowertype[type].get_cell_atlas_coords(Vector2i(newfound[0].x, newfound[0].y)) in ATLAS_OFFSETS.values():
			returns.append(boards[newfound[0].z].get_flower_at_cell(Vector2i(newfound[0].x, newfound[0].y)))
		
		var adjacent: Array[Vector3i] = get_cells_connected_to_cell_3d(newfound[0])
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
	var layer2: TileMapLayer = board2.flowertype[type]
	
	var atlascoords2: Vector2i = layer2.get_cell_atlas_coords(portal2.cell + direction)
	
	if atlascoords2 == EMPTY_ATLAS_COORDS:
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
			pass # Overpass
			return NULL_RETURN


#endregion
