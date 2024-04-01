extends Node3D

@onready var player = $"../../../Player"

@onready var laser = $Laser
@onready var box_target = $BoxTarget

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position.z = player.position.z - 20

func scale_to(scale: float):
	var scale_vec = Vector3(scale, scale, scale)
	laser.scale = scale_vec
	box_target.scale = scale_vec
