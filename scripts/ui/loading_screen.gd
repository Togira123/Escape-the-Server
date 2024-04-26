extends Control

@onready var player_camera = $"../PlayerCamera"
@onready var TUNNEL = preload("res://scenes/tunnel.tscn")

var moved = false
var old_pos: Vector3
var old_rot: Vector3

func _ready():
	old_pos = player_camera.position
	old_rot = player_camera.rotation

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not moved:
		player_camera.position.y = 3
		player_camera.position.z = -2
		player_camera.position.x = 0
		player_camera.rotation.x = -13.8 / 180 * PI
		var tunnel = TUNNEL.instantiate()
		tunnel.position.z = 50
		add_child(tunnel)
		moved = true
	else:
		player_camera.position = old_pos
		player_camera.rotation = old_rot
		queue_free()
	
