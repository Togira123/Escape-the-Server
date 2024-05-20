extends Camera3D

@onready var player = $"../Player"
@onready var main = $"../../Main"

@export var curve: Curve

var time = 0.0
var rotate_angle = 0.0

var last_player_velocity = 0.0

# when player finishes
var cur_cam_speed: float = -1

# for teleport
var distance_to_player = 2.0

var player_died = false

func _ready():
	set_process(false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if player.player_state == player.State.DEAD:
		player_died = true
		if last_player_velocity == 0:
			last_player_velocity = player.cur_speed
		rotate_angle = (last_player_velocity - player.cur_speed) * (PI / 4 / last_player_velocity)
		if rotate_angle > PI / 4:
			set_process(false)
		var sine = sin(rotate_angle)
		position.y = player.position.y + 1 + sine * 2
		position.z = player.position.z - cos(rotate_angle) * 2
		rotation.x = (-13.8 - (sine * 25)) / 90 * PI
	elif player.player_state == player.State.FINISHED:
		if player.reached_height:
			Engine.set_time_scale(lerp(Engine.time_scale, 1.0, 0.05))
			if cur_cam_speed == -1:
				cur_cam_speed = player.speed
			cur_cam_speed -= delta * 20
			if cur_cam_speed < 0:
				cur_cam_speed = 0
				player.set_physics_process(false)
				player.game_over.emit(false)
				set_process(false)
			position.z += cur_cam_speed * delta
		else:
			Engine.set_time_scale(lerp(Engine.time_scale, 0.075, 0.05))
			position.y = player.position.y + 1
			position.x = player.position.x
			position.z = player.position.z - 2
	else:
		if player_died:
			player_died = move_camera_down(delta)
		if distance_to_player > 2:
			distance_to_player = max(distance_to_player - delta * 256, 2)
		elif distance_to_player < 2:
			distance_to_player = 2
		position.z = player.position.z - distance_to_player
		position.x = player.position.x
		position.y = player.position.y + 1
		last_player_velocity = player.velocity.z

func move_camera_down(delta):
	time += delta
	if time > 1:
		rotation.x = -13.8 / 180 * PI
		position.y = 3
		set_process(true)
		time = 0.0
		return false
	else:
		var pos = curve.sample(time);
		position.y = 7 - (pos * (7 - player.position.y - 1))
		rotation.x = (-75 + (pos * 61.2)) / 180 * PI
	position.z = lerp(position.z, player.position.z - 2, 0.6)
	return true
