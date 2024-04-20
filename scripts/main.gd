extends Node

const LOADING_SCREEN = preload("res://scenes/ui/loading_screen.tscn")
const END_MENU_DEFEAT = preload("res://scenes/ui/end_menu_defeat.tscn")
const END_MENU_VICTORY = preload("res://scenes/ui/end_menu_victory.tscn")

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
		if col >= 1.0:
			Engine.set_time_scale(1.0)
			black_screen.queue_free()
			$Level/UI.visible = false
			if player.is_finished:
				# player has won
				var end_menu = END_MENU_VICTORY.instantiate()
				add_child(end_menu)
			else:
				# player died
				var end_menu = END_MENU_DEFEAT.instantiate()
				add_child(end_menu)
			set_process(false)
		black_screen.set_color(Color(0, 0, 0, clamp(col + delta, 0.0, 1.0)))
		return
	if not start_running and not move_camera_down:
		set_process(false)
		return
	if start_running and not player.start_running(delta):
		start_running = false
	if move_camera_down and not player_camera.move_camera_down(delta):
		move_camera_down = false

func restart_game():
	# make sure floor looks the same again
	$Constants.ground_pattern_color_change_progress = 0
	player_soul.get_tree().call_group("module", "change_color_of_pattern")
	get_tree().reload_current_scene()
	player_soul.mesh.material.set_shader_parameter("turned_on", false)
	mesh.material_override.set_shader_parameter("dissolve_amount", 0.0)
	# make sure time scale is back to normal
	Engine.set_time_scale(1.0)

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
