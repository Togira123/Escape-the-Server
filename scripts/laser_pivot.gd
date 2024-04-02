extends Node3D

@onready var laser = $Laser
@onready var box_target = $BoxTarget

func scale_to(scale: float):
	var scale_vec = Vector3(scale, scale, scale)
	laser.scale = scale_vec
	box_target.scale = scale_vec
