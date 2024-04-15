extends Camera3D

@onready var player = $"../Player"
@onready var main = $"../../Main"

@export var curve: Curve

var time = 0.0

func _ready():
	set_process(false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position.z = player.position.z - 2
	position.x = player.position.x
	position.y = player.position.y + 1

func move_camera_down(delta):
	time += delta
	if time > 1:
		rotation.x = -13.8 / 180 * PI
		position.y = 2
		set_process(true)
		return false
	else:
		var pos = curve.sample(time);
		position.y = 7 - (pos * (7 - player.position.y - 1))
		rotation.x = (-75 + (pos * 61.2)) / 180 * PI
		#rotation.x = lerp(rotation.x, -13.8 / 180 * PI, 0.5)
		#print(position.x)
	position.z = lerp(position.z, player.position.z - 2, 0.55)
	return true
