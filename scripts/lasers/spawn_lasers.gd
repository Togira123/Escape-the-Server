extends Node3D

@onready var player = $"../../Player"
@onready var level = $"../../Level"

const LASER_PIVOT = preload("res://scenes/lasers/laser_pivot.tscn")
const X_OFFSET = 80
const LASER_COUNT = [3, 4, 5]
const LASER_SCALE = [1.67, 1.33, 1]
const LASER_EMISSION = [10, 14, 18]
const LASER_EMISSION_COLORS: Array[Color] = [Color(0.0, 1.0, 0.0), Color(1.0, 1.0, 0.0), Color(1.0, 0.0, 0.0)]

var is_transitioning = false
var inst

# Called when the node enters the scene tree for the first time.
func _ready():
	spawn_lasers(level.stage)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# make all lasers move with the player
	if not player.is_finished:
		position.z = player.position.z - 20
	if is_transitioning:
		var mat = inst.get_child(1).get_surface_override_material(0)
		var cur_col = mat.get_shader_parameter("emission")
		if cur_col == LASER_EMISSION_COLORS[level.stage]:
			is_transitioning = false
			return
		mat.set_shader_parameter("emission", cur_col.lerp(LASER_EMISSION_COLORS[level.stage], 0.02))

func spawn_lasers(stage: int):
	var floor_offset = (3 + 0.25 * (2 - stage))
	var space_between_lasers = (3 + (2 - stage))
	for i in range(LASER_COUNT[stage]):
		inst = LASER_PIVOT.instantiate()
		inst.position.y = floor_offset + space_between_lasers * i
		inst.position.x = X_OFFSET
		var mat = inst.get_child(1).get_surface_override_material(0)
		mat.set_shader_parameter("emission_energy", LASER_EMISSION[level.stage])
		#mat.set_shader_parameter("emission", LASER_EMISSION_COLORS[level.stage])
		is_transitioning = true
		add_child(inst)
		inst.scale_to(LASER_SCALE[stage])
	
	for i in range(LASER_COUNT[stage]):
		var inst = LASER_PIVOT.instantiate()
		inst.position.y = floor_offset + space_between_lasers * i
		inst.position.x = -X_OFFSET
		add_child(inst)
		inst.scale_to(LASER_SCALE[stage])

func remove_children():
	for n in get_children():
		if n.name != "LaserHitboxLeft" and n.name != "LaserHitboxRight":
			remove_child(n)
			n.queue_free()
