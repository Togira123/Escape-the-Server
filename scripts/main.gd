extends Node

const LOADING_SCREEN = preload("res://scenes/ui/loading_screen.tscn")

@onready var player_camera = $PlayerCamera
@onready var player = $Player
@onready var player_soul = $Player/PlayerSoul
@onready var mesh = $Player/Armature/Skeleton3D/Cube

var in_level = false

var start_running = true
var move_camera_down = true

var game_over = false
# black screen at the end of the game
var black_screen: ColorRect

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if game_over:
		var col = black_screen.get_color().a;
		if col > 0.98:
			get_tree().reload_current_scene()
			player_soul.mesh.material.set_shader_parameter("turned_on", false)
			mesh.material_override.set_shader_parameter("dissolve_amount", 0.0)
		black_screen.set_color(Color(0, 0, 0, lerp(col, 1.0, 0.01)))
		return
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


func _on_player_game_over():
	var ins = LOADING_SCREEN.instantiate()
	black_screen = ins.get_child(0)
	black_screen.set_color(Color(0, 0, 0, 0))
	game_over = true
	add_child(ins)
	set_process(true)
	
