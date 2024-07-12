extends Control

@onready var player_camera = $"../PlayerCamera"
@onready var level_ui = $"../Level/UI/"
@onready var building_indicator = $"../Level/BuildingIndicator"

const TUNNEL = preload("res://scenes/tunnel.tscn")
const JUMPPAD_GREEN = preload("res://scenes/jumppads/green_jumppad.tscn")
const JUMPPAD_YELLOW = preload("res://scenes/jumppads/yellow_jumppad.tscn")
const BUILD_CEILING = preload("res://scenes/building/Ceiling.tscn")
const BUILD_RAMP = preload("res://scenes/building/Ramp.tscn")
const BOLT = preload("res://scenes/building/Bolt.tscn")

const LOBBY_MUSIC = preload("res://assets/audio/music/Lobby.mp3")
const TRACK1 = preload("res://assets/audio/music/Track1.mp3")
const TRACK2 = preload("res://assets/audio/music/Track2.mp3")
const TRACK3 = preload("res://assets/audio/music/Track3.mp3")
const WIN_MUSIC = preload("res://assets/audio/music/Win.mp3")
const DEATH_MUSIC = preload("res://assets/audio/music/Death.mp3")

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
		for i in range(5):
			var bolt = BOLT.instantiate()
			bolt.position.y = 5
			bolt.position.x = -20 + i * 10
			bolt.position.z = 25
			add_child(bolt)
		frames -= 1
		AudioServer.register_stream_as_sample(LOBBY_MUSIC)
		AudioServer.register_stream_as_sample(TRACK1)
		AudioServer.register_stream_as_sample(TRACK2)
		AudioServer.register_stream_as_sample(TRACK3)
		AudioServer.register_stream_as_sample(WIN_MUSIC)
		AudioServer.register_stream_as_sample(DEATH_MUSIC)
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
