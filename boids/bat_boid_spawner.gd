extends Node2D

@export var size:Vector2 = Vector2(100,100)
@export var numBoids:int = 20
@export var boidScene:PackedScene
@export var tilemap:TileMap
@export var border:float = 25.0
@export var destroyMargin:float = 100.0  # Marge avant destruction

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
	boids_logic()

func spawnBoids():
	for i in range(numBoids):
		var boid:BatBoid = boidScene.instantiate()
		boid.position.x = position.x + randf_range(-50, 50)
		boid.position.y = position.y + randf_range(-50, 50)
		
		boids.append(boid)
		add_sibling(boid)

func boids_logic():
	for boid in boids:
		# Vérifier si le boid est hors map
		if is_outside_map(boid):
			remove_boid(boid)
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
		boid.moveAway(closeBoids, 100)
		
		boid.move()
		
func is_outside_map(boid: BatBoid) -> bool:
	if not mapBounds:
		print("no map bounds")
		return false
	
	# Zone de destruction
	var destroyBounds = Rect2(
		mapBounds.position - Vector2(destroyMargin, destroyMargin), 
		mapBounds.size + Vector2(destroyMargin * 2, destroyMargin * 2)
	)
	
	return not destroyBounds.has_point(boid.position)

func remove_boid(boid: BatBoid):
	boids.erase(boid)
	print("boid: " + str(boid) + "destroyed")
	boid.queue_free()
