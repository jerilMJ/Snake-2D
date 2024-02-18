extends Node2D

var level_rect: Rect2
var food_scene: PackedScene = preload("res://scenes/items/food.tscn")
var food_compass_scene: PackedScene = preload("res://scenes/items/food_compass.tscn")
var food_compass: FoodCompass
var food: Node2D
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var score: int = 0


func _ready():
	rng.randomize()
	var grass_plains_map: TileMap = $GrassPlains/TileMap as TileMap
	level_rect = grass_plains_map.get_used_rect()
	place_food_randomly()


func _process(delta):
	if Input.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	_place_food_compass()


func _place_food_compass():
	var food_coords: Vector2 = food.global_position as Vector2
	var player_coords: Vector2 = ($Player/PrimaryParts as Node2D).global_position
	var point = MyUtils.get_point_on_line_at_distance_from_p1(
		player_coords, food_coords, 500
	)
	if food_compass:
		food_compass.queue_free()
	food_compass = food_compass_scene.instantiate() as FoodCompass
	var target: Node2D = food_compass.get_child(1)
	food_compass.orient(point)
	target.rotation = lerp_angle(target.rotation, player_coords.angle_to_point(point), 1)
	add_child(food_compass)


func _on_player_food_signal(position):
	score += 1
	($GameUI/ScoreCounter as Label).text = "Score: " + str(score)
	food.queue_free()
	place_food_randomly()


func place_food_randomly():
	var player_pos: Vector2 = $Player/PrimaryParts/InteractArea.global_position
	var player_tile: Rect2 = MyUtils.convert_coords_to_tile(player_pos).tile
	var random_food_tile: Rect2 = Rect2(
		Vector2(
			# Subtracting 1 so it is not placed on the borders
			rng.randi_range(1, level_rect.size.x - 1),
			rng.randi_range(1, level_rect.size.y - 1)
		),
		Constants.TILE_SIZE
	)
	food = food_scene.instantiate() as Food
	food.orient(MyUtils.convert_tile_to_coords(random_food_tile).coords)
	$Items.add_child(food)
