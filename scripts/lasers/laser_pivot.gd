extends Node3D

@onready var laser = $Laser

func scale_to(new_scale: float):
	var scale_vec = Vector3(new_scale, new_scale, new_scale)
	laser.scale = scale_vec
