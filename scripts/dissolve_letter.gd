extends RigidBody3D

@onready var world_glow: WorldEnvironment = $Glow
@onready var mesh = $Pivot/MeshInstance3D
@onready var hitbox_collision = $LetterHitbox/CollisionShape3D

func _ready():
	set_physics_process(false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	var old_val = mesh.material_override.get_shader_parameter("dissolve_amount")
	if old_val == 1:
		set_physics_process(false)
		self.get_parent().remove_child(self)
	mesh.material_override.set_shader_parameter("dissolve_amount", old_val + 0.025)

func dissolve():
	#world_glow.environment.glow_enabled = true
	set_physics_process(true)
	hitbox_collision.set_deferred("disabled", true)


func _on_letter_hitbox_area_entered(area):
	dissolve()
