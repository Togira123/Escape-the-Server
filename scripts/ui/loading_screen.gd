extends Control

@onready var player_camera = $"../PlayerCamera"
@onready var level_ui = $"../Level/UI/"
@onready var building_indicator = $"../Level/BuildingIndicator"
var TUNNEL = preload("res://scenes/tunnel.tscn")
var JUMPPAD_GREEN = preload("res://scenes/jumppads/green_jumppad.tscn")
var JUMPPAD_YELLOW = preload("res://scenes/jumppads/yellow_jumppad.tscn")
var BUILD_CEILING = preload("res://scenes/building/Ceiling.tscn")
var BUILD_RAMP = preload("res://scenes/building/Ramp.tscn")

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
		var green_pad = JUMPPAD_GREEN.instantiate()
		green_pad.position.z = 50
		var yellow_pad = JUMPPAD_YELLOW.instantiate()
		yellow_pad.position.z = 60
		yellow_pad.position.x = 10
		add_child(green_pad)
		add_child(yellow_pad)
		prev_player_pos = player.position.z
		player.position.z = 10
		var ceiling = BUILD_CEILING.instantiate()
		ceiling.position.z = 30
		ceiling.position.y = 10
		add_child(ceiling)
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
			building_indicator.visible = true
			var ramp = BUILD_RAMP.instantiate()
			ramp.position.z = 30
			add_child(ramp)
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
			building_indicator.visible = false
			Client.showed_loading_screen = true
		frames -= 1
	else:
		player_camera.position = old_pos
		player_camera.rotation = old_rot
		queue_free()
