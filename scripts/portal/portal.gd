extends MeshInstance3D
 
class_name CamPortal
 
@export var destination: Node3D

var helper: Node3D
 
func _ready():
	helper = $Helper
	visible = true
	$Inside.visible = true
 
func _process(delta):
	var main_cam = get_viewport().get_camera_3d()
	helper.global_transform = main_cam.global_transform
	destination.get_child(0).transform = helper.transform
	Global.portal_camera.global_transform = destination.get_child(0).global_transform
	var diff = global_transform.origin - main_cam.global_transform.origin
	var angle = main_cam.global_transform.basis.z.angle_to(diff)
	var near_plane = helper.transform.origin.length()*abs(cos(angle))
	Global.portal_camera.near = max(0.1, near_plane-4.2)
