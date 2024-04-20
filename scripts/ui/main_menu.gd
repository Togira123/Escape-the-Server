extends Control

signal game_start

@onready var player = $"../Player"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

var arrived = false
var x = 6 - (randi() % 12)
var z = 3 - (randi() % 6)

func set_timer():
	set_physics_process(false)
	await get_tree().create_timer(randi() % 3 + 1, true, true).timeout	
	set_physics_process(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if arrived:
		# make sure not same numbers as before are picked
		var prev_x = x
		var prev_z = z
		while true:
			x = 6 - (randi() % 12)
			z = 3 - (randi() % 6)
			if prev_x != x or prev_z != z:
				break
		set_timer()
		arrived = false
	else:
		arrived = player.move_to_random_point(x, z, delta)

func _on_game_start_button_pressed():
	game_start.emit()
	# remove main menu from scene tree
	queue_free()
