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
			var tile_id = tilemap.get_cell_source_id(0, cell)
			var walkable = _is_cell_walkable(cell)
			grid[cell] = walkable

	print("--- GRID DONE (", grid.size(), " cells ) ---")

func _is_cell_walkable(cell: Vector2i) -> bool:
	# Ici on vérifie chaque couches de la tilemap
	for layer in range(tilemap.get_layers_count()):
		var tile_data = tilemap.get_cell_tile_data(layer, cell)
		
		if tile_data == null:
			continue
		
		# Si la tile a pas de collision, elle n'est pas walkable
		if tile_data.get_collision_polygons_count(0) > 0:
			return false
		
	return true

# ---------------- DIJKSTRA ----------------

func dijkstra(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	if not grid.get(start, false):
		return []
	if not grid.get(goal, false):
		return []

	var dist: = {}
	var prev: = {}
	var visited: = {}

	# priority queue = Array of pairs [distance, cell]
	var queue: Array = []
	
	dist[start] = 0
	queue.append([0, start])

	while queue.size() > 0:
		# --- extract-min (binary heap behavior) ---
		queue.sort()  # small array → ok, but MUCH smaller than before
		var current = queue.pop_front()[1]

		if visited.has(current):
			continue
		visited[current] = true

		if current == goal:
			break

		for n in _get_neighbors(current):
			if visited.has(n):
				continue

			var alt = dist.get(current, INF) + 1
			if alt < dist.get(n, INF):
				dist[n] = alt
				prev[n] = current
				queue.append([alt, n])

	return _reconstruct_path(prev, start, goal)

func _get_neighbors(cell: Vector2i) -> Array:
	var neighbors: Array[Vector2i] = []
	var dirs = [
		Vector2i(1, 0), Vector2i(-1, 0),
		Vector2i(0, 1), Vector2i(0, -1)
	]

	for d in dirs:
		var n = cell + d
		if grid.has(n) and grid[n]:
			neighbors.append(n)

	return neighbors


func _reconstruct_path(prev: Dictionary, start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []

	# Cas trivial : pas de parent pour le goal → chemin impossible
	if not prev.has(goal) and start != goal:
		return path

	var node = goal

	while true:
		path.append(node)

		# Si on a atteint le départ, c'est fini
		if node == start:
			break

		# Vérifier que prev contient bien un parent
		if not prev.has(node):
			# Chemin cassé → retour chemin vide
			return []

		node = prev[node]

	path.reverse()
	return path


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

	print("\n[Update Path] start:", start, " goal:", goal)

	var cells = dijkstra(start, goal)
	path = _cells_to_world_path(cells)

	if path.is_empty():
		print("[Update Path] WARNING: empty path!")

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

	if (target_player != null):
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


#func _draw():
	#if path.size() > 1:
		#for i in range(path.size() - 1):
			#draw_line(path[i] - global_position, path[i+1] - global_position, Color.YELLOW, 2)
#
#func _process(delta):
	#queue_redraw()
