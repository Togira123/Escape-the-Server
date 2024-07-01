extends Camera3D
 
var main_cam: Camera3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_transform = main_cam.global_transform
