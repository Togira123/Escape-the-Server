extends Control

@onready var player_camera = $"../PlayerCamera"
@onready var level_ui = $"../Level/UI/"
var TUNNEL = preload("res://scenes/tunnel.tscn")

@onready var player = $"../Player"

var frames = 5
var old_pos: Vector3
var old_rot: Vector3

var prev_player_pos
var prev_shield_val
var prev_heat_bar_val
var prev_heat_effect_val
var heat_control_val

func _ready():
	if Client.showed_loading_screen:
		queue_free()
	old_pos = player_camera.position
	old_rot = player_camera.rotation

# pre-compile shaders
func _process(_delta):
	if frames == 5:
		player_camera.position.y = 3
		player_camera.position.z = -2
		player_camera.position.x = 0
		player_camera.rotation.x = -13.8 / 180 * PI
		var tunnel = TUNNEL.instantiate()
		tunnel.position.z = 150
		add_child(tunnel)
		prev_player_pos = player.position.z
		player.position.z = 10
		frames -= 1
	elif frames > 0:
		if frames == 4:
			prev_shield_val = player.get_node("PlayerShield").mesh.material.get_shader_parameter("alpha")
			player.get_node("PlayerShield").mesh.material.set_shader_parameter("alpha", 0.5)
			prev_heat_bar_val = level_ui.get_node("Heat/HeatBar").material.get_shader_parameter("alpha")
			heat_control_val = level_ui.get_node("Heat").modulate
			level_ui.get_node("Heat").modulate = Color(1.0, 1.0, 1.0, 1.0)
			level_ui.get_node("Heat/HeatBar").material.set_shader_parameter("alpha", 1.0)
			prev_heat_effect_val = level_ui.get_node("HeatEffect").material.get_shader_parameter("alpha")
			level_ui.get_node("HeatEffect").material.set_shader_parameter("alpha", 1.0)
			level_ui.get_node("Arrow").visible = true
		elif frames == 3:
			$"../MainMenu".get_node("Settings").visible = true
		elif frames == 1:
			player.get_node("PlayerShield").mesh.material.set_shader_parameter("alpha", prev_shield_val)
			level_ui.get_node("Heat").modulate = heat_control_val
			level_ui.get_node("Heat/HeatBar").material.set_shader_parameter("alpha", prev_heat_bar_val)
			level_ui.get_node("HeatEffect").material.set_shader_parameter("alpha", prev_heat_effect_val)
			level_ui.get_node("Arrow").visible = false
			$"../MainMenu".get_node("Settings").visible = false
			player.position.z = prev_player_pos
			print("Preload finished!")
			Client.showed_loading_screen = true
		frames -= 1
	else:
		player_camera.position = old_pos
		player_camera.rotation = old_rot
		queue_free()
