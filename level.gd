extends Node2D
var food_scene = preload("res://scenes/food.tscn")
var food
var rng = RandomNumberGenerator.new()
var tilemap
var tilemap_area
var food_tile

# Called when the node enters the scene tree for the first time.
func _ready():
	print(MyUtilities.convert_point_to_tile(Vector2(1280, 0)))
	food = food_scene.instantiate()
	add_child(food)
	#food.position = Vector2(rng.randi_range(0, 1000), rng.randi_range(0, 1000))
	tilemap = ($Map as TileMap)
	var tilemap_start = MyUtilities.convert_point_to_tile(tilemap.position)
	tilemap_area = tilemap.get_used_rect()
	var x = rng.randi_range(tilemap_start.x, tilemap_start.x + tilemap_area.size.x)
	var y = rng.randi_range(tilemap_start.y, tilemap_start.y + tilemap_area.size.y)
	food_tile = Vector2(x, y)
	food.position = MyUtilities.convert_tile_to_point(food_tile)
	print(food_tile)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
