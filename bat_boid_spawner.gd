extends Node2D

@export var size:Vector2 = Vector2(100,100)
@export var maxVelocity:int = 10
@export var numBoids:int = 20
@export var boids:Array[BatBoid]
@export var boidScene:PackedScene
@export var spawnPoint:Vector2 = Vector2(100,100)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	boids = []


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func spawnBoids():
	for i in range(numBoids):
		var boid:BatBoid = boidScene.instantiate()
		boid.position.x = randi_range(0,spawnPoint[0])
		boid.position.x = randi_range(0,spawnPoint[1])
		boids.append(boid)
