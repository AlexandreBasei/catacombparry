extends Node2D

@export var mobs_to_spawn:Array[PackedScene]

@onready var spawn_timer = $SpawnTimer
@onready var player = $Player
@onready var map = $Map
@onready var boid_spawner = $BatBoidSpawner
@onready var boid_timer = $BoidTimer
@onready var health_bar = $CanvasLayer/HealthBar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	boid_spawner.exclusion_zones = map.get_children()
	boid_spawner.repulsion_zones = map.get_children()
	health_bar.init_HP(player.maxHp)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func start_game():
	#spawn_timer.start()
	boid_timer.start()
	player.show()
	player.game_started = true

func _on_spawn_timer_timeout() -> void:
	spawnMob()

func spawnMob():
	var mob = mobs_to_spawn[randi_range(0,1)].instantiate()
	mob.target_player = player
	mob.tilemap = map
	var negativeX = randi_range(0,1)
	var negativeY = randi_range(0,1)
	
	if negativeX == 0:
		if negativeY == 0:
			mob.position = Vector2(player.position.x + randf_range(150, 200), player.position.y + randf_range(150,200))
		else:
			mob.position = Vector2(player.position.x + randf_range(150,200), player.position.y - randf_range(150,200))
	else:
		if negativeY == 0:
			mob.position = Vector2(player.position.x - randf_range(150,200), player.position.y + randf_range(150,200))
		else:
			mob.position = Vector2(player.position.x - randf_range(150,200), player.position.y - randf_range(150,200))
	
	add_child(mob)


func _on_player_player_dead() -> void:
	spawn_timer.stop()
	boid_timer.stop()
	Hud.player_dead()

func _on_player_hurt(damage: int) -> void:
	health_bar._set_health(health_bar.health - damage)

func _on_boid_timer_timeout() -> void:
	boid_spawner.spawnBoids()
