extends Node2D

@export var mobToSpawn:PackedScene

@onready var spawnTimer = $SpawnTimer
@onready var player = $Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawnTimer.start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_spawn_timer_timeout() -> void:
	pass # Replace with function body.

func spawnMob():
	var mob = mobToSpawn.instantiate()
	mob.targetPlayer = player
	var negativeX = randi_range(0,1)
	var negativeY = randi_range(0,1)
	
	if negativeX == 0:
		if negativeY == 0:
			mob.position = [player.position.x + randf_range(100, 30), player.position.y + randf_range(100, 30)]
		else:
			mob.position = [player.position.x + randf_range(100, 30), player.position.y - randf_range(100, 30)]
	else:
		if negativeY == 0:
			mob.position = [player.position.x - randf_range(100, 30), player.position.y + randf_range(100, 30)]
		else:
			mob.position = [player.position.x - randf_range(100, 30), player.position.y - randf_range(100, 30)]
	
	add_child(mob)
