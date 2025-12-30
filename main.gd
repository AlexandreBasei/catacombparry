extends Node2D

@export var mobs_to_spawn:Array[PackedScene]
@export var default_spawn_cooldown_diminution:float = 5.0

@onready var spawn_timer = $SpawnTimer
@onready var player = $Player
@onready var player_spawn = $PlayerSpawn
@onready var map = $Map
@onready var sk_spawwner:Array[Node] = $SkeletonSpawner.get_children()
@onready var boid_spawner = $BatBoidSpawner
@onready var boid_timer = $BoidTimer
@onready var health_bar = $CanvasLayer/HealthBar

var spawn_cooldown_diminution:float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	boid_spawner.exclusion_zones = map.get_children()
	boid_spawner.repulsion_zones = map.get_children()
	boid_spawner.spawn_points = sk_spawwner
	health_bar.init_HP(player.maxHp)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func start_game():
	var mobs:Array[Node] = get_tree().get_nodes_in_group("mobs")
	
	for mob in mobs:
		mob.queue_free()
	
	spawn_timer.wait_time = default_spawn_cooldown_diminution
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
	Hud.start_timer()

func _on_spawn_timer_timeout() -> void:
	spawnMob()

func spawnMob():
	var mob = mobs_to_spawn[randi_range(0,1)].instantiate()
	mob.target_player = player
	mob.tilemap = map
	mob.position = sk_spawwner[randi_range(0, sk_spawwner.size() - 1)].position # Spawn aléatoire entre tous les points de spawn
	
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
	boid_spawner.spawnBoids()
