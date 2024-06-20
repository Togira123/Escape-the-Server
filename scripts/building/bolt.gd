extends Node3D

@onready var bolt = $Bolt
@onready var player = $/root/Main/Player

const WEIGHTS_GREEN = [0.5, 0.8, 1, 1, 0.8, 0.3]
const WEIGHTS_YELLOW = [0.4, 0.8, 1, 1, 0.8, 0.5, 0.2]

var time = 0.0
var being_picked_up = false
var spin_speed = 4
# amount of materials this bolt gives
var materials = 0

func _ready():
	if Client.ranked_rand.randi() % 3 == 0:
		bolt.mesh.surface_get_material(1).emission = Color("00ff00")
		spin_speed = 2
		materials = 5 + Client.ranked_rand.rand_weighted(WEIGHTS_GREEN)
	else:
		materials = 9 + Client.ranked_rand.rand_weighted(WEIGHTS_GREEN)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if being_picked_up:
		position = position.lerp(player.position, 0.5)
		scale = scale.lerp(Vector3(0.1, 0.1, 0.1), 0.5)
		if position.distance_squared_to(player.position) < 0.05:
			player.pick_up_bolt()
			queue_free()
	else:
		bolt.rotation.y += delta * spin_speed
		if bolt.rotation.y > 360:
			bolt.rotation.y -= 360
		time += delta
		position.y = 2.5 + sin(time) / 4.0

func start_pick_up():
	being_picked_up = true
