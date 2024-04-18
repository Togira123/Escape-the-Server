extends Camera3D

@onready var player = $"../Player"
@onready var main = $"../../Main"

@export var curve: Curve

var time = 0.0
var rotate_angle = 0.0

var last_player_velocity = 0.0

func _ready():
	set_process(false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if player.is_dead:
		if last_player_velocity == 0:
			last_player_velocity = player.cur_speed
		rotate_angle = (last_player_velocity - player.cur_speed) * (PI / 4 / last_player_velocity)
		if rotate_angle > PI / 4:
			set_process(false)
		var sine = sin(rotate_angle)
		position.y = player.position.y + 1 + sine * 2
		position.z = player.position.z - cos(rotate_angle) * 2
		rotation.x = (-13.8 - (sine * 25)) / 90 * PI
	else:
		position.z = player.position.z - 2
		position.x = player.position.x
		position.y = player.position.y + 1
		last_player_velocity = player.velocity.z

func move_camera_down(delta):
	time += delta
	if time > 1:
		rotation.x = -13.8 / 180 * PI
		position.y = 3
		set_process(true)
		return false
	else:
		var pos = curve.sample(time);
		position.y = 7 - (pos * (7 - player.position.y - 1))
		rotation.x = (-75 + (pos * 61.2)) / 180 * PI
	position.z = lerp(position.z, player.position.z - 2, 0.6)
	return true
