extends Node

@onready var player_camera = $PlayerCamera
@onready var player = $Player

var in_level = false

var start_running = true
var move_camera_down = true

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not start_running and not move_camera_down:
		set_process(false)
		return
	if start_running and not player.start_running(delta):
		start_running = false
	if move_camera_down and not player_camera.move_camera_down(delta):
		move_camera_down = false
		


func _on_main_menu_game_start():
	set_process(true)
	in_level = true
