extends Node2D

@export var mobs_to_spawn:Array[PackedScene]
@export var default_spawn_cooldown_diminution:float = 5.0

@onready var spawn_timer = $SpawnTimer
@onready var player = $Player
@onready var player_spawn = $PlayerSpawn
@onready var map = $Map
@onready var mob_spawwner:Array[Node] = $MobSpawner.get_children()
@onready var boid_spawner = $MobSpawner
@onready var boid_timer = $BoidTimer
@onready var health_bar = $CanvasLayer/HealthBar

var spawn_cooldown_diminution:float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	boid_spawner.exclusion_zones = map.get_children()
	boid_spawner.repulsion_zones = map.get_children()
	health_bar.init_HP(player.maxHp)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func start_game():
	var mobs:Array[Node] = get_tree().get_nodes_in_group("mobs")
	
	for mob in mobs:
		mob.queue_free()
	
	var boids:Array[Node] = get_tree().get_nodes_in_group("boid")
	
	spawn_timer.wait_time = default_spawn_cooldown_diminution
	
	for boid in boids:
		boid.queue_free()
	
	spawn_cooldown_diminution = 0.0
	
	health_bar._set_health(player.maxHp)
	player.position = player_spawn.position
	player.hp = player.maxHp
	player.current_state = player.PlayerState.Idle
	player.show()
	player.shield.show()
	
	#spawn_timer.start()
	boid_timer.start()
	player.game_started = true

func _on_spawn_timer_timeout() -> void:
	spawnMob()

func spawnMob():
	var mob = mobs_to_spawn[randi_range(0,1)].instantiate()
	mob.target_player = player
	mob.tilemap = map
	mob.position = mob_spawwner[randi_range(0, mob_spawwner.size() - 1)].position # Spawn aléatoire entre tous les points de spawn
	
	add_child(mob)
	
	if spawn_timer.wait_time > 1.0 :
		spawn_timer.wait_time -= spawn_cooldown_diminution + 0.1

func _on_player_player_dead() -> void:
	spawn_timer.stop()
	boid_timer.stop()
	Hud.player_dead()

func _on_player_hurt(damage: int) -> void:
	health_bar._set_health(health_bar.health - damage)

func _on_boid_timer_timeout() -> void:
	var boid_spawn_point = mob_spawwner[randi_range(0, mob_spawwner.size() - 1)].position
	boid_spawner.spawnBoids(boid_spawn_point)
