extends Node2D

@export var mobs_to_spawn:Array[PackedScene]

@onready var spawn_timer = $SpawnTimer
@onready var player = $Player
@onready var map = $Map

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn_timer.start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

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
			mob.position = Vector2(player.position.x + randf_range(150, 50), player.position.y + randf_range(150, 50))
		else:
			mob.position = Vector2(player.position.x + randf_range(150, 50), player.position.y - randf_range(150, 50))
	else:
		if negativeY == 0:
			mob.position = Vector2(player.position.x - randf_range(150, 50), player.position.y + randf_range(150, 50))
		else:
			mob.position = Vector2(player.position.x - randf_range(150, 50), player.position.y - randf_range(150, 50))
	
	add_child(mob)
