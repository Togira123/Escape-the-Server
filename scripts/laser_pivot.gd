extends Node3D

@onready var laser = $Laser

func scale_to(scale: float):
	var scale_vec = Vector3(scale, scale, scale)
	laser.scale = scale_vec
