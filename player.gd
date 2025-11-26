extends CharacterBody2D

signal hurt(damage:int)
signal player_dead

@export var speed = 350
@export var friction = 0.5
@export var acceleration = 0.3
@export var maxHp:int = 100
@export var orbit_distance: float = 50.0

@onready var animations = $AnimatedSprite2D
@onready var shield = $Shield
@onready var shield_col = $Shield/CollisionShape2D
@onready var parry_timer = $ParryCooldownTimer
@onready var light = $PointLight2D
@onready var camera = $Camera2D

var hp:int
var is_walking:bool = false
var is_dead:bool = false
var is_damaged:bool = false
var is_parrying:bool = false
var parry_in_cooldown:bool = false
var mob_in_shield:Node2D

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
		parry()
		
	return input

func _physics_process(delta):
	var direction = get_input()
	if direction.length() > 0:
		if (!is_dead):
			velocity = velocity.lerp(direction.normalized() * speed, acceleration)
			is_walking = true
			
			if (direction.x < 0):
				animations.flip_h = true
			else:
				animations.flip_h = false
	else:
		velocity = velocity.lerp(Vector2.ZERO, friction)
		is_walking = false
		
	if (is_walking and !is_parrying and !is_dead and !is_damaged):
		animations.play("walk")
	if (!is_walking and !is_parrying and !is_dead and !is_damaged):
		animations.play("idle")
		
	_update_shield()

	move_and_slide()
	
	var colmob = get_last_slide_collision()
	
	if (colmob and colmob.get_collider().is_in_group("mobs")):
		takeDamage(colmob.get_collider().damages)
		colmob.get_collider().die()

func _update_shield():
	if (shield == null):
		return
		
	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - global_position).normalized()
	
	shield.global_position = global_position + dir * orbit_distance
	
	shield.rotation = dir.angle() + PI / 2

func parry():
	if (!parry_in_cooldown and !is_dead):
		is_parrying = true
		if (!is_dead):
			animations.play("parry")
		if (mob_in_shield):
			camera.apply_shake()
			mob_in_shield.die()
		parry_in_cooldown = true
	

func takeDamage(dmg:int):
	is_damaged = true
	hp -= dmg
	hurt.emit(dmg)
	
	if hp <=0 :
		hp = 0
		is_damaged = false
		is_dead = true
		animations.play("death")
		player_dead.emit()
		return
	
	animations.play("hurt")

func _on_animated_sprite_2d_animation_finished() -> void:
	var last_anim = animations.get_animation()
	
	if (last_anim == "parry"):
		is_parrying = false
		parry_in_cooldown = false
	if (last_anim == "hurt"):
		is_damaged = false
	if (last_anim == "death"):
		shield.hide()
		light.hide()


func _on_shield_body_entered(body: Node2D) -> void:
	if body.is_in_group("mobs"):
		mob_in_shield = body


func _on_shield_body_exited(body: Node2D) -> void:
	if body.is_in_group("mobs"):
		mob_in_shield = null
