extends MeshInstance3D

@onready var camera = $"../PlayerCamera"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	position.z = camera.position.z + 550
