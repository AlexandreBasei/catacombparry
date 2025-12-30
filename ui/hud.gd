extends CanvasLayer

var main:Node
@onready var message = $Message
@onready var start_btn = $StartButton
@onready var game_timer_label = $GameTimer

var elapsed_time:float = 0.0
var timer_running:bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main = get_parent().get_node("Main")
	game_timer_label.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if timer_running:
		elapsed_time += delta
		update_timer_display()

func update_timer_display():
	var seconds = int(elapsed_time)
	var milliseconds = int((elapsed_time - seconds) * 100)
	game_timer_label.text = "%02d.%02d" % [seconds, milliseconds]

func start_timer():
	elapsed_time = 0.0
	timer_running = true
	game_timer_label.show()
	update_timer_display()

func stop_timer():
	timer_running = false

func player_dead():
	stop_timer()
	message.text = "Game Over"
	start_btn.text= "Restart"
	message.show()
	start_btn.show()


func _on_start_button_button_down() -> void:
	message.hide()
	start_btn.hide()
	main.start_game()
