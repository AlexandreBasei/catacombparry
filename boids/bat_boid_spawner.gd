extends Node2D

@export var size:Vector2 = Vector2(100,100)
@export var numBoids:int = 20
@export var boidScene:PackedScene
@export var tilemap:TileMap
@export var border:float = 25.0
@export var destroy_margin:float = 100.0  # Marge avant destruction
@export var min_distance:float = 50
@export var player:CharacterBody2D
@export var player_attraction:float = 50.0  # Force d'attraction vers le joueur
@export var exclusion_zones:Array[Node] = []  # Zones où les boids ignorent le joueur
@export var repulsion_zones:Array[Node] = []  # Zones où les boids ne peuvent pas aller
@export var repulsion_force:float = 100.0  # Force de répulsion des zones

var boids:Array[BatBoid] = []
var mapBounds:Rect2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if tilemap:
		mapBounds = tilemap.get_used_rect()
		#Convertir en coordonnées monde
		var tileSize = Vector2(tilemap.tile_set.tile_size)
		mapBounds = Rect2(
			Vector2(mapBounds.position) * tileSize,
			Vector2(mapBounds.size) * tileSize
			)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	boids_logic(delta)

func spawnBoids(spawn_pos):
	for i in range(numBoids):
		var boid:BatBoid = boidScene.instantiate()
		boid.position = spawn_pos
		
		boids.append(boid)
		add_sibling(boid)

func boids_logic(delta:float):
	for boid in boids:
		if is_instance_valid(boid):
			# Vérifier si le boid est hors map
			if is_outside_map(boid):
				remove_boid(boid)
				continue
				
			# Si le boid est en fuite, il continue en ligne droite
			if boid.is_fleeing:
				boid.move()
				continue
				
			#Logique de flocking
			var closeBoids:Array[BatBoid] = []
			for otherBoid in boids:
				if otherBoid == boid: continue
				var dist = boid.distance(otherBoid)
				if dist < 200:
					closeBoids.append(otherBoid)
			
			boid.moveCloser(closeBoids)
			boid.moveWith(closeBoids)
			boid.moveAway(closeBoids, min_distance)
			
			# Répulsion des zones interdites
			var is_in_repulsion = apply_zone_repulsion(boid)
			
			if is_in_repulsion:
				boid.add_repulsion_time(delta)
				if boid.repulsion_time >= boid.repulsion_threshold:
					boid.start_fleeing()
			else:
				boid.reset_repulsion_time()
			
			# Attirer vers le joueur si il n'est pas sur une lumière
			if player:
				boid.moveTowards(player.position, player_attraction)
			
			boid.move()

func is_player_in_exclusion_zone() -> bool:
	if not player:
		return false
		
	for zone in exclusion_zones:
		if not zone:
			continue
			
		var shape_node = zone.get_node_or_null("CollisionShape2D")
		if not shape_node:
			continue
		
		var shape = shape_node.shape
		
		# Zone circulaire (bougies)
		if shape is CircleShape2D:
			var dist = player.global_position.distance_to(zone.global_position)
			if dist <= shape.radius:
				return true
			# Zone rectangulaire
			elif shape is RectangleShape2D:
				var rect = Rect2(
					zone.global_position - shape.size / 2,
					shape.size
				)
				if rect.has_point(player.global_position):
					return true
	return false

func apply_zone_repulsion(boid:BatBoid):
	var is_being_repulsed = false
	
	for zone in repulsion_zones:
		if not zone:
			continue
		
		var shape_node = zone.get_node_or_null("CollisionShape2D")
		if not shape_node:
			continue
		
		var shape = shape_node.shape
		
		# Zone circulaire
		if shape is CircleShape2D:
			var dist = boid.position.distance_to(zone.global_position)
			# Appliquer répulsion si proche ou dans la zone
			if dist < shape.radius + 100:  # 50 pixels de marge
				boid.moveAwayFrom(zone.global_position, repulsion_force, shape.radius + 50)
				is_being_repulsed = true
	
	return is_being_repulsed

func is_outside_map(boid: BatBoid) -> bool:
	if not mapBounds:
		print("no map bounds")
		return false
	
	# Zone de destruction
	var destroyBounds = Rect2(
		mapBounds.position - Vector2(destroy_margin, destroy_margin), 
		mapBounds.size + Vector2(destroy_margin * 2, destroy_margin * 2)
	)
	
	return not destroyBounds.has_point(boid.position)

func remove_boid(boid: BatBoid):
	boids.erase(boid)
	print("boid: " + str(boid) + "destroyed")
	boid.queue_free()
