extends RigidBody3D

@onready var mesh = $Pivot/MeshInstance3D
@onready var letter_hitbox = $LetterHitbox

func _ready():
	set_physics_process(false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	var old_val = mesh.material_override.get_shader_parameter("dissolve_amount")
	if old_val == 1:
		set_physics_process(false)
		self.get_parent().remove_child(self)
	mesh.material_override.set_shader_parameter("dissolve_amount", old_val + 0.025)

func dissolve():
	set_physics_process(true)
	for c in letter_hitbox.get_children():
		c.set_deferred("disabled", true)
	if has_node("ShieldHitbox"):
		for c in $ShieldHitbox.get_children():
			c.set_deferred("disabled", true)


func _on_letter_hitbox_area_entered(_area):
	dissolve()
