extends CanvasLayer

var main:Node
@onready var message = $Message
@onready var start_btn = $StartButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main = get_parent().get_node("Main")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func player_dead():
	message.text = "Game Over"
	start_btn.text= "Restart"
	message.show()
	start_btn.show()


func _on_start_button_button_down() -> void:
	message.hide()
	start_btn.hide()
	main.start_game()
