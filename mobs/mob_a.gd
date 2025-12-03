extends CharacterBody2D

@export var speed = 350
@export var friction = 0.5
@export var acceleration = 0.3
@export var damages:int = 10

@export var repath_interval := 0.5

@onready var animations = $AnimatedSprite2D
@onready var collisions = $CollisionShape2D

var is_dead:bool = false
var target_player: CharacterBody2D
var tilemap:TileMap

var grid = {}
var path: Array[Vector2] = []
var path_index := 0

var repath_timer := 0.0

func _ready() -> void:
	_build_grid()


# ---------------- GRILLE ----------------

func _build_grid():
	grid.clear()

	var used_rect = tilemap.get_used_rect()

	for x in range(used_rect.position.x, used_rect.position.x + used_rect.size.x):
		for y in range(used_rect.position.y, used_rect.position.y + used_rect.size.y):
			var cell = Vector2i(x, y)
			var walkable = _is_cell_walkable(cell)
			grid[cell] = walkable

	print("--- GRID DONE (", grid.size(), " cells ) ---")


func _is_cell_walkable(cell: Vector2i) -> bool:
	for layer in range(tilemap.get_layers_count()):
		var tile_data = tilemap.get_cell_tile_data(layer, cell)
		
		if tile_data == null:
			continue
		
		if tile_data.get_collision_polygons_count(0) > 0:
			return false
		
	return true


# ---------------- A* ----------------

func astar(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	if not grid.get(start, false):
		return []
	if not grid.get(goal, false):
		return []

	var g_score := {}  # Coût réel depuis le départ
	var f_score := {}  # g_score + heuristique
	var prev := {}
	var visited := {}

	var queue: Array = []
	
	g_score[start] = 0
	f_score[start] = _heuristic(start, goal)
	queue.append([f_score[start], start])

	while queue.size() > 0:
		queue.sort()
		var current = queue.pop_front()[1]

		if visited.has(current):
			continue
		visited[current] = true

		if current == goal:
			break

		for n in _get_neighbors(current):
			if visited.has(n):
				continue

			var tentative_g = g_score.get(current, INF) + 1
			
			if tentative_g < g_score.get(n, INF):
				prev[n] = current
				g_score[n] = tentative_g
				f_score[n] = tentative_g + _heuristic(n, goal)
				queue.append([f_score[n], n])

	return _reconstruct_path(prev, start, goal)


func _heuristic(a: Vector2i, b: Vector2i) -> float:
	# Distance euclidienne
	return Vector2(a - b).length()


func _get_neighbors(cell: Vector2i) -> Array:
	var neighbors: Array[Vector2i] = []
	var dirs = [
		Vector2i(1, 0), Vector2i(-1, 0),
		Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(1, -1),
		Vector2i(-1, 1), Vector2i(-1, -1)
	]

	for d in dirs:
		var n = cell + d
		if grid.has(n) and grid[n]:
			if abs(d.x) == 1 and abs(d.y) == 1:
				var adj_h = cell + Vector2i(d.x, 0)
				var adj_v = cell + Vector2i(0, d.y)
				if not grid.get(adj_h, false) or not grid.get(adj_v, false):
					continue
			neighbors.append(n)

	return neighbors


func _reconstruct_path(prev: Dictionary, start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	if not prev.has(goal) and start != goal:
		return result

	var node = goal

	while true:
		result.append(node)

		if node == start:
			break

		if not prev.has(node):
			return []

		node = prev[node]

	result.reverse()
	return result


# ---------------- CONVERSION EN WORLD POS ----------------

func _cells_to_world_path(cells):
	var world_path:Array[Vector2] = []
	for c in cells:
		world_path.append(tilemap.to_global(tilemap.map_to_local(c)))
	return world_path


# ---------------- UPDATE / FOLLOW PATH ----------------

func _physics_process(delta):
	if is_dead or target_player == null:
		return

	repath_timer -= delta
	if repath_timer <= 0.0:
		_update_path()
		repath_timer = repath_interval

	_follow_path(delta)
	move_and_slide()


func _update_path():
	var local_pos = tilemap.to_local(global_position)
	var start = tilemap.local_to_map(local_pos)
	
	var player_local_pos = tilemap.to_local(target_player.global_position)
	var goal = tilemap.local_to_map(player_local_pos)

	var cells = astar(start, goal)
	path = _cells_to_world_path(cells)

	path_index = 0


func _follow_path(delta):
	if path.is_empty():
		velocity = velocity.lerp(Vector2.ZERO, friction)
		return

	var target = path[path_index]
	var dir = target - global_position

	if dir.length() < 6.0:
		path_index += 1
		if path_index >= path.size():
			path.clear()
			return

	velocity = velocity.lerp(dir.normalized() * speed, acceleration)

	if target_player != null:
		animations.flip_h = target_player.global_position.x < global_position.x
	
	if not is_dead:
		animations.play("run")


# ---------------- DEATH ----------------

func die():
	is_dead = true
	collisions.disabled = true
	animations.play("death")


func _on_animated_sprite_2d_animation_finished() -> void:
	if animations.get_animation() == "death":
		queue_free()
