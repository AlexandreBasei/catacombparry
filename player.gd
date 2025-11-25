extends CharacterBody2D

@export var speed = 350
@export var friction = 0.5
@export var acceleration = 0.3
@export var maxHp:int = 100
@export var orbit_distance: float = 50.0

@onready var animations = $AnimatedSprite2D
@onready var orbit_object = $Shield

var hp:int
var isWalking:bool = false
var isDead:bool = false
var isParrying:bool = false

func _ready() -> void:
	hp = maxHp

func get_input():
	var input = Vector2()
	if Input.is_action_pressed('right'):
		input.x += 1
	if Input.is_action_pressed('left'):
		input.x -= 1
	if Input.is_action_pressed('down'):
		input.y += 1
	if Input.is_action_pressed('up'):
		input.y -= 1
	if Input.is_action_pressed('parry'):
		isParrying = true
		if (!isDead):
			animations.play("parry")
		
	return input

func _physics_process(delta):
	var direction = get_input()
	if direction.length() > 0:
		velocity = velocity.lerp(direction.normalized() * speed, acceleration)
		isWalking = true
		if direction.x < 0:
			animations.flip_h = true
		else:
			animations.flip_h = false
	else:
		velocity = velocity.lerp(Vector2.ZERO, friction)
		isWalking = false
		
	if (isWalking and !isParrying and !isDead):
		animations.play("walk")
	if (!isWalking and !isParrying and !isDead):
		animations.play("idle")
		
	_update_orbit_object()
	
	move_and_slide()

func _update_orbit_object():
	if (orbit_object == null):
		return
		
	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - global_position).normalized()
	
	orbit_object.global_position = global_position + dir * orbit_distance
	
	orbit_object.rotation = dir.angle() + PI / 2

func takeDamage(dmg:int):
	hp -= dmg
	
	if hp <=0 :
		hp = 0
		isDead = true
		animations.play("death")
		return
	
	animations.play("hurt")



func _on_animated_sprite_2d_animation_finished() -> void:
	var lastAnim = animations.get_animation()
	
	if (lastAnim == "parry"):
		isParrying = false
