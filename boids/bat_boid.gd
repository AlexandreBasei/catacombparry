extends Area2D

class_name BatBoid

@export var damages:float = 2.0
@export var speed:float = 20
@export var maxVelocity:float = 100
@export var attraction:float = 200
@export var repulsion:float = 2
@export var move_near:float = 40

@onready var sprite = $AnimatedSprite2D
@onready var collision = $CollisionShape2D

var velocityX = randi_range(1,10) / 10.0
var velocityY = randi_range(1,10) / 10.0

# État de fuite
var is_fleeing:bool = false
var flee_direction:Vector2 = Vector2.ZERO
var repulsion_time:float = 0.0  # Temps passé dans une zone de répulsion
@export var repulsion_threshold:float = 2.0  # Secondes avant de fuir

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
	
	velocityX += (avgX / move_near)
	velocityY += (avgY / move_near)
	
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
	
	if velocityX < 0:
		sprite.flip_h = false
	elif velocityX > 0:
		sprite.flip_h = true
	
	position.x += velocityX
	position.y += velocityY

func moveTowards(targetPos: Vector2, attractionForce: float):
	var dirX = targetPos.x - position.x
	var dirY = targetPos.y - position.y
	
	# Normaliser la direction
	var dist = sqrt(dirX * dirX + dirY * dirY)
	if dist > 0:
		velocityX += (dirX / dist) * (attractionForce / dist) * 10
		velocityY += (dirY / dist) * (attractionForce / dist) * 10

func moveAwayFrom(targetPos: Vector2, repulsionForce: float, maxDistance: float):
	var dirX = position.x - targetPos.x
	var dirY = position.y - targetPos.y
	
	var dist = sqrt(dirX * dirX + dirY * dirY)
	if dist > 0 and dist < maxDistance:
		# Plus on est proche, plus la répulsion est forte
		var strength = (maxDistance - dist) / maxDistance
		velocityX += (dirX / dist) * repulsionForce * strength
		velocityY += (dirY / dist) * repulsionForce * strength

func add_repulsion_time(delta: float):
	repulsion_time += delta
	
func reset_repulsion_time():
	repulsion_time = 0.0
	
func start_fleeing():
	if is_fleeing: return
	is_fleeing = true
	collision.disabled = true
	speed += 30
	
	var angle = randf() * TAU  # Angle aléatoire entre 0 et 2*PI
	flee_direction = Vector2(cos(angle), sin(angle))

func stop_fleeing():
	is_fleeing = false
	repulsion_time = 0.0
	collision.disabled = false
	speed -= 30


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.takeDamage(damages)
		start_fleeing()
