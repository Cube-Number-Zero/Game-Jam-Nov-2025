class_name Portal extends Node2D

var linked_portal: Portal
var cell: Vector2i

static var all_portal_list: Array[Portal] = [] ## A list of all portals



func _ready() -> void:
	all_portal_list.append(self)



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
