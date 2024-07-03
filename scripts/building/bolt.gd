extends Node3D

@onready var bolt = $Bolt
@onready var player = $/root/Main/Player

const WEIGHTS_GREEN = [0.5, 0.8, 1, 1, 0.8, 0.3]
const WEIGHTS_YELLOW = [0.4, 0.8, 1, 1, 0.8, 0.5, 0.2]

var lerp = 0.5
var time = 0.0
var being_picked_up = false
var spin_speed = 4
# amount of materials this bolt gives
var materials = 0
var infinite = false

func _ready():
	if infinite:
		bolt.mesh.surface_get_material(1).emission = Color("ffffff")
		materials = -1
	elif Client.ranked_rand.randi() % 3 == 0:
		bolt.mesh.surface_get_material(1).emission = Color("00ff00")
		spin_speed = 2
		materials = 5 + Client.ranked_rand.rand_with_weight(WEIGHTS_GREEN)
	else:
		materials = 9 + Client.ranked_rand.rand_with_weight(WEIGHTS_GREEN)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if being_picked_up:
		global_position = global_position.lerp(player.global_position, lerp)
		scale = scale.lerp(Vector3(0.1, 0.1, 0.1), 0.5)
		if global_position.distance_squared_to(player.global_position) < 0.2:
			player.pick_up_bolt(materials)
			queue_free()
		else:
			lerp += delta / 2.0
	else:
		bolt.rotation.y += delta * spin_speed
		if bolt.rotation.y > 360:
			bolt.rotation.y -= 360
		time += delta
		position.y = 2 + sin(time) / 4.0

func start_pick_up():
	being_picked_up = true
