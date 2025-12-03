extends Area2D

class_name BatBoid

@export var speed:float = 20
@export var maxVelocity:float = 100
@export var attraction:float = 200
@export var repulsion:float = 2

var velocityX = randi_range(1,10) / 10.0
var velocityY = randi_range(1,10) / 10.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func distance(boid:BatBoid):
	var distX = position.x - boid.position.x
	var distY = position.y - boid.position.y
	return sqrt(distX * distX + distY * distY)

func moveCloser(boids:Array[BatBoid]):
	if len(boids) < 1 : return
	
	var avgX = 0
	var avgY = 0
	
	for boid in boids:
		if boid.position.x == position.x and boid.position.y == position.y:
			continue
		avgX += (position.x - boid.position.x)
		avgY += (position.y - boid.position.y)
	
	avgX /= len(boids)
	avgY /= len(boids)
	
	velocityX -= (avgX / attraction)
	velocityY -= (avgY / attraction)
	
func moveWith(boids:Array[BatBoid]):
	if len(boids) < 1 : return
	
	var avgX = 0
	var avgY = 0
	
	for boid in boids:
		avgX += boid.velocityX
		avgY += boid.velocityY
	avgX /= len(boids)
	avgY /= len(boids)
	
	velocityX += (avgX / 40)
	velocityY += (avgY / 40)
	
func moveAway(boids:Array[BatBoid], minDistance:float):
	if len(boids) < 1 : return
	
	var distanceX = 0
	var distanceY = 0
	var numClose = 0
	
	for boid in boids:
		var distance = distance(boid)
		if distance < minDistance:
			numClose += 1
			var xdiff = (position.x - boid.position.x)
			var ydiff = (position.y - boid.position.y)
			if xdiff >= 0:  xdiff = sqrt(minDistance) - xdiff
			elif xdiff < 0:  xdiff = -sqrt(minDistance) - xdiff
			if ydiff >= 0:  ydiff = sqrt(minDistance) - ydiff
			elif ydiff < 0:  ydiff = -sqrt(minDistance) - ydiff
			distanceX += xdiff
			distanceY += ydiff
	if numClose == 0:
		return
	
	velocityX -= distanceX / repulsion
	velocityY -= distanceY / repulsion
	
func move():
	if abs(velocityX) > maxVelocity or abs(velocityY) > maxVelocity:
		var scaleFactor = maxVelocity / max(abs(velocityX), abs(velocityY))
		
		velocityX *= scaleFactor
		velocityY *= scaleFactor
	
	position.x += velocityX
	position.y += velocityY
