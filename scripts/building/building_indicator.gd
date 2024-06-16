extends Node3D

@onready var level = $"../../Level"
@onready var player = $"../../Player"
@onready var cube = $"Cube"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	set_process(false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position.x = ceil(player.position.x * 5 / 100) * 20 - 10
	position.z = ceil(player.position.z / 40) * 40 + 20
	var needed_ind = int(ceil(player.position.z / 40) * 2 + 1) % level.LOADED_MODULES_SIZE
	var module = level.loaded_modules[needed_ind]
	if module.built_at.has(int(position.x)) or player.material_count < 10:
		cube.mesh.surface_get_material(0).set_shader_parameter("color", Color("ff0000"))
	else:
		cube.mesh.surface_get_material(0).set_shader_parameter("color", Color("00ffff"))
