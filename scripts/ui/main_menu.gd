extends Control

signal game_start

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



func _on_game_start_button_pressed():
	game_start.emit()
	# remove main menu from scene tree
	queue_free()
