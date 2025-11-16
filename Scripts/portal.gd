class_name Portal extends Node2D

var linked_portal: Portal
var cell: Vector2i

static var all_portal_list: Array[Portal] = [] ## A list of all portals

const PORTAL_REMOVAL_CHANCE: float = 0.75 ## The odds this portal will be removed when PortalRemovalTimer expires, if this portal is not being used

func _ready() -> void:
	all_portal_list.append(self)


func _process(_delta: float) -> void:
	#TESTING ONLY!
	if not is_queued_for_deletion():
		assert($"../../TileMapLayer1".get_cell_atlas_coords(cell) == Board.PORTAL_ATLAS_COORDS)
		assert($"../../TileMapLayer2".get_cell_atlas_coords(cell) == Board.PORTAL_ATLAS_COORDS)
		assert($"../../TileMapLayer3".get_cell_atlas_coords(cell) == Board.PORTAL_ATLAS_COORDS)


static func link_portals(portal1: Portal, portal2: Portal) -> void:
	portal1.linked_portal = portal2
	portal2.linked_portal = portal1

static func update_colors() -> void:
	for i: int in range(len(all_portal_list)):
		@warning_ignore("integer_division")
		var j = i / 2
		var portal = all_portal_list[i]
		@warning_ignore("integer_division")
		var hue = float(j) / float(len(all_portal_list) / 2)
		portal.get_node(^"Sprite2D").self_modulate = Color.from_hsv(hue, 0.8, 1.0)
		portal.get_node(^"Label").text = str(j + 1)
		portal.get_node(^"Label").self_modulate = Color.from_hsv(fmod(hue + 0.5, 1.0), 0.4, 1.0)

func check_for_portal_decay() -> void:
	if not is_queued_for_deletion():
		if $"../..".is_portal_connected(cell): return
		if linked_portal.get_node(^"../..").is_portal_connected(linked_portal.cell): return
		delete_portal_pair()
		# No connections! Delete me!

func delete_portal_pair() -> void:
	$"../..".delete_portal(cell)
	linked_portal.get_node(^"../..").delete_portal(linked_portal.cell)
	all_portal_list.erase(self)
	all_portal_list.erase(linked_portal)
	self.queue_free()
	linked_portal.queue_free()
	update_colors()

func _on_portal_removal_timer_timeout() -> void:
	check_for_portal_decay()
