extends Node3D

@onready var bolt = $Bolt
@onready var player = $/root/Main/Player

var time = 0.0
var being_picked_up = false
var spin_speed = 4

func _ready():
	if randi() % 2:
		bolt.mesh.surface_get_material(1).emission = Color("00ff00")
		spin_speed = 2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if being_picked_up:
		position = position.lerp(player.position, 0.5)
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
