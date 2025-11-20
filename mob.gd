extends CharacterBody2D

@export var speed = 350
@export var friction = 0.5
@export var acceleration = 0.3
@export var damages:int = 10

@onready var animations = $AnimatedSprite2D

var isDead:bool = false
var targetPlayer

func _physics_process(delta):
	var direction = (targetPlayer.position - position).normalized;
	if direction.length() > 0:
		velocity = velocity.lerp(direction * speed, acceleration)
		if direction.x < 0:
			animations.flip_h = true
		else:
			animations.flip_h = false
	else:
		velocity = velocity.lerp(Vector2.ZERO, friction)
		
	if (!isDead):
		animations.play("run")
		
	move_and_slide()

func die():
	isDead = true
	animations.play("death")
	queue_free()
	
	animations.play("hurt")



func _on_animated_sprite_2d_animation_finished() -> void:
	var lastAnim = animations.get_animation()
	
	if (lastAnim == "death"):
		queue_free()
