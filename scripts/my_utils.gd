extends Node
class_name Utils

var constants: Resource


class TileInfo:
	var tile: Rect2
	var coords: Vector2
	var global_coords: Vector2


func _ready():
	constants = load("res://scripts/constants.gd")


func convert_coords_to_tile(pos: Vector2):
	var tile_size = constants.TILE_SIZE
	var ti = TileInfo.new()
	ti.tile = Rect2(Vector2(int(pos.x / tile_size.x), int(pos.y / tile_size.y)), tile_size)
	ti.coords = pos
	return ti


func convert_tile_to_coords(tile: Rect2):
	var ti = TileInfo.new()
	ti.tile = tile
	ti.coords = Vector2(tile.position.x * tile.size.x, tile.position.y * tile.size.y)
	return ti


func get_point_on_line_at_distance_from_p1(p1: Vector2, p2: Vector2, dist: float):
	var p1p2_dist = p1.distance_to(p2)
	var p3: Vector2 = Vector2()
	p3.x = p1.x - ((dist * (p1.x - p2.x)) / p1p2_dist)
	p3.y = p1.y - ((dist * (p1.y - p2.y)) / p1p2_dist)
	print(p1, " - ", p2, " = ", p3)
	return p3
