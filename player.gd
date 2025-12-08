extends CharacterBody2D

signal hurt(damage:int)
signal player_dead

@export var speed:float = 350
@export var friction:float = 0.5
@export var acceleration:float = 0.3
@export var maxHp:int = 100
@export var orbit_distance: float = 50.0

@onready var animations = $AnimatedSprite2D
@onready var shield = $Shield
@onready var shield_col = $Shield/CollisionShape2D
@onready var parry_timer = $ParryCooldownTimer
@onready var light = $PointLight2D
@onready var camera = $Camera2D

var game_started:bool = false
var facing_left:bool = false

enum PlayerState {
	Idle,
	Walking,
	Parrying,
	Damaged,
	Dead
}

var hp:int
var parry_in_cooldown:bool = false
var mob_in_shield:Node2D

# Default state
var current_state = PlayerState.Idle

func _ready() -> void:
	hp = maxHp

func get_input():
	var input = Vector2()
	if game_started:
		if Input.is_action_pressed('right'):
			input.x += 1
		if Input.is_action_pressed('left'):
			input.x -= 1
		if Input.is_action_pressed('down'):
			input.y += 1
		if Input.is_action_pressed('up'):
			input.y -= 1
	
	return input

func _physics_process(delta):
	var direction = get_input()
		
	handle_state_actions(direction)
	handle_state_transitions(direction)
	
	_update_shield()
	move_and_slide()
	
	var colmob = get_last_slide_collision()
	
	if (colmob and colmob.get_collider().is_in_group("mobs")):
		takeDamage(colmob.get_collider().damages)
		colmob.get_collider().die()

func handle_state_transitions(direction:Vector2) -> void:
	# Ne pas changer d'état si on est mort, en train de parry ou damaged
	if current_state == PlayerState.Dead:
		return
	if current_state == PlayerState.Parrying:
		return
	if current_state == PlayerState.Damaged:
		return
	
	if hp <= 0:
		current_state = PlayerState.Dead
	elif Input.is_action_just_pressed('parry') and !parry_in_cooldown:
		current_state = PlayerState.Parrying
	elif direction.length() > 0:
		current_state = PlayerState.Walking
	else:
		current_state = PlayerState.Idle

func handle_state_actions(direction:Vector2) -> void:
	match current_state:
		PlayerState.Dead:
			hp = 0
			# Jouer l'animation seulement si elle n'est pas déjà en cours
			if animations.animation != "death":
				animations.play("death")
				velocity = Vector2.ZERO
				player_dead.emit()
			
		PlayerState.Damaged:
			if animations.animation != "hurt":
				animations.play("hurt")
				velocity = Vector2.ZERO
		
		PlayerState.Parrying:
			if animations.animation != "parry":
				animations.play("parry")
				velocity = Vector2.ZERO
				if (mob_in_shield):
					camera.apply_shake()
					mob_in_shield.die()
				parry_in_cooldown = true
			
		PlayerState.Walking:
			velocity = velocity.lerp(direction.normalized() * speed, acceleration)
			if (direction.x < 0):
				facing_left = true
				animations.flip_h = true
			elif (direction.x > 0):
				facing_left = false
				animations.flip_h = false
			animations.play("walk")
			
		PlayerState.Idle:
			velocity = velocity.lerp(Vector2.ZERO, friction)
			animations.flip_h = facing_left
			animations.play("idle")

func _update_shield():
	if (shield == null):
		return
		
	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - global_position).normalized()
	
	shield.global_position = global_position + dir * orbit_distance
	
	shield.rotation = dir.angle() + PI / 2
	
func takeDamage(dmg:int):
	if current_state == PlayerState.Dead:
		return
	current_state = PlayerState.Damaged
	hp -= dmg
	hurt.emit(dmg)

func _on_animated_sprite_2d_animation_finished() -> void:
	var last_anim = animations.get_animation()
	
	if (last_anim == "parry"):
		parry_in_cooldown = false
		current_state = PlayerState.Idle
	if (last_anim == "hurt"):
		parry_in_cooldown = false
		current_state = PlayerState.Idle
	if (last_anim == "death"):
		shield.hide()
		light.hide()


func _on_shield_body_entered(body: Node2D) -> void:
	if body.is_in_group("mobs"):
		mob_in_shield = body


func _on_shield_body_exited(body: Node2D) -> void:
	if body.is_in_group("mobs"):
		mob_in_shield = null
