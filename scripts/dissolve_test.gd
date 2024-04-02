extends RigidBody3D

@onready var world_glow: WorldEnvironment = $Glow
@onready var mesh = $Pivot/MeshInstance3D
@onready var hitbox_collision = $Hitbox/CollisionShape3D

var is_dissolving = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if is_dissolving:
		var old_val = mesh.material_override.get_shader_parameter("dissolve_progress")
		if old_val == 1:
			is_dissolving = false
		mesh.material_override.set_shader_parameter("dissolve_progress", lerp(old_val, 1.0, 0.1))

func dissolve():
	#world_glow.environment.glow_enabled = true
	is_dissolving = true
	hitbox_collision.disabled = true
