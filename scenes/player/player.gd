extends Node2D

signal food_signal(position: Vector2)

enum DIRECTION {LEFT, DOWN, RIGHT, UP}


var direction: DIRECTION = DIRECTION.RIGHT
var prev_direction: DIRECTION = DIRECTION.UP
var head: CharacterBody2D
var mid_sections: Node2D
var tail: Node2D
var tile_history: Array[MyUtils.TileInfo] = []
@export var speed = 1000.0
@export var rotation_speed = 0.8
@export var length: int = 0
var coords_to_tile: Callable
var mid_section_texture: Texture2D
var collider_queue: Array[Node2D] = []
var hp: int = 3
var is_invincible: bool = false
var is_dead: bool = false

var line
var area_2d
var collision_poly: CollisionPolygon2D 
var damage_particles: Array[CPUParticles2D] = []


func _ready():
	mid_section_texture = load("res://graphics/sprites/snake_texture_vflip.png")
	head = $PrimaryParts as CharacterBody2D
	mid_sections = $MidSections as Node2D
	tail = $Tail as Node2D
	var ti = MyUtils.convert_coords_to_tile(head.position)
	ti.global_coords = head.global_position
	tile_history.append(ti)

	line = Line2D.new()
	area_2d = Area2D.new()

	collision_poly = CollisionPolygon2D.new()
	area_2d.add_child(collision_poly)
	line.add_child(area_2d)
	line.texture = mid_section_texture
	line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	line.width = 46
	area_2d.connect("body_entered", _on_mid_section_body_entered)
	mid_sections.add_child(line)
	
	for particle in $PrimaryParts/DamageParticles.get_children():
		damage_particles.append(particle as CPUParticles2D)


func _process(delta):
	if is_dead:
		return
	process_interactions()


func _physics_process(delta):
	process_mid_section()
	if is_dead:
		return
	if hp <= 0:
		print("dead")
		head.velocity = Vector2.ZERO
		is_dead = true
	process_movement(delta)


func _show_damage():
	for particle in damage_particles:
		if not particle.emitting:
			particle.restart()
			particle.emitting = true


func _on_invincibility_timeout():
	is_invincible = false


func _on_mid_section_body_entered(body: Node2D):
	if is_invincible or is_dead:
		return
	if body.is_in_group("player_head"):
		AudioManager.play_sound("res://audio/bash.mp3")
		_show_damage()
		hp -= 1
		var timer = Timer.new()
		timer.one_shot = true
		add_child(timer)
		timer.connect("timeout", _on_invincibility_timeout)
		timer.wait_time = 3.0
		is_invincible = true
		timer.start()


func process_movement(delta):
	var horizontal_direction = Input.get_axis("move_left", "move_right")
	var vertical_direction = Input.get_axis("move_up", "move_down")
	if horizontal_direction:
		var dir = DIRECTION.RIGHT if horizontal_direction > 0 else DIRECTION.LEFT
		if not is_opposite_direction(dir, prev_direction):
			head.velocity.x = horizontal_direction * speed
			head.velocity.y = 0
			prev_direction = direction
			direction = dir
	elif vertical_direction:
		var dir = DIRECTION.DOWN if vertical_direction > 0 else DIRECTION.UP
		if not is_opposite_direction(dir, prev_direction):
			head.velocity.x = 0
			head.velocity.y = vertical_direction * speed
			prev_direction = direction
			direction = dir
	match direction:
		DIRECTION.LEFT:
			head.rotation = lerp_angle(head.rotation, PI, rotation_speed)
		DIRECTION.RIGHT:
			head.rotation = lerp_angle(head.rotation, 0.0, rotation_speed)
		DIRECTION.UP:
			head.rotation = lerp_angle(head.rotation, 1.5 * PI, rotation_speed)
		DIRECTION.DOWN:
			head.rotation = lerp_angle(head.rotation, 0.5 * PI, rotation_speed)
	head.move_and_slide()


func get_polygon_points(point_a: Vector2, point_b: Vector2, thickness: float):
	var vector_diff = point_a - point_b
	var normal = vector_diff.rotated(PI * 0.5).normalized()
	var offset = normal * thickness * 0.5
	return {
		"group_a": [point_a + offset, point_b + offset],
		"group_b": [point_a - offset, point_b - offset]
	}


func process_mid_section():
	if line and line.get_point_count() > 0:
		line.clear_points()
	add_tile_history()
	
	var head_connector_length = 40
	var points: Array[Vector2] = []
	match direction:
		DIRECTION.LEFT:
			points.append(Vector2(head.position.x + head_connector_length, head.position.y))
		DIRECTION.RIGHT :
			points.append(Vector2(head.position.x - head_connector_length, head.position.y))
		DIRECTION.UP:
			points.append(Vector2(head.position.x, head.position.y + head_connector_length))
		DIRECTION.DOWN:
			points.append(Vector2(head.position.x, head.position.y - head_connector_length))
	for i in range(length - 1, -1, -1):
		if len(tile_history) >= length:
			points.append(tile_history[i].coords)
	points.append(tail.position)
	var polygon_points: Array[Vector2] = []
	var polygon_points_a: Array[Vector2] = []
	var polygon_points_b: Array[Vector2] = []
	
	for i in range(len(points)):
		# Drawing the line segments
		line.add_point(points[i])
		# Adding the colliders for each line segment
		if i > 2:
			var pts = get_polygon_points(points[i-1], points[i], line.width)
			polygon_points_a.append_array(pts["group_a"])
			polygon_points_b.append_array(pts["group_b"])
	
	polygon_points.append_array(polygon_points_a)
	polygon_points_b.reverse()
	polygon_points.append_array(polygon_points_b)
	collision_poly.polygon = polygon_points
	
	if tile_history.is_empty():
		tail.look_at(head.global_position)
	else:
		tail.look_at(tile_history[0].global_coords)


func process_interactions():
	var areas: Array[Area2D] = $PrimaryParts/InteractArea.get_overlapping_areas()
	# check if overlapping with food
	if not areas.is_empty() and areas[0].get_groups().any(func(group): return group == "food"):
		AudioManager.play_sound("res://audio/eating.mp3")
		length += 1
		food_signal.emit(position)


func is_opposite_direction(dir: DIRECTION, prev: DIRECTION):
	return abs(prev - dir) == 2


func add_tile_history():
	var ti = MyUtils.convert_coords_to_tile(head.position)
	ti.global_coords = head.global_position
	if !tile_history.back().tile.is_equal_approx(ti.tile):
		if len(tile_history) == length + 1:
			var last_move = tile_history.pop_front()
			var tween = get_tree().create_tween()
			tween.tween_property(tail, "position", last_move.coords, 0.2)
		tile_history.append(ti)
