extends Node3D

const SHORT_LASER_PIVOT = preload("res://scenes/laser_pivot_short.tscn")
const TUNNEL_SCENE = preload("res://scenes/tunnel.tscn")
const OFFSET: int = 20
const LOADED_MODULES_SIZE: int = 32
const TUNNELS = [800, 6000]
const TUNNEL_LENGTH = 250

@onready var tunnels = $"Tunnels"
@export var modules: Array[PackedScene] = []
var loaded_modules = []
var amount = 10

var next_tunnel = 0

var module_count: int = 0

var stage = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	loaded_modules.resize(LOADED_MODULES_SIZE)
	for n in amount:
		spawn_module(module_count * OFFSET)


func spawn_module(n: int):
	var instance = modules[0 if n < 10 * OFFSET or (next_tunnel > 0 and n >= TUNNELS[next_tunnel - 1] and n <= TUNNELS[next_tunnel - 1] + 13 * OFFSET) else randi() % modules.size()].instantiate()
	instance.position.z = n
	var index: int = (n / OFFSET) % LOADED_MODULES_SIZE
	var prev_ind = LOADED_MODULES_SIZE - 1 if index == 0 else index - 1
	if loaded_modules[index]:
		loaded_modules[index].queue_free()
	loaded_modules[index] = instance
	# add lasers if stage > 0
	if stage > 0:
		var i = SHORT_LASER_PIVOT.instantiate()
		i.rotation.y = PI / 2
		i.position.x = -95.0
		i.position.z = 0.0
		instance.add_child(i)

	if loaded_modules[prev_ind]:
		var prev_inst = loaded_modules[prev_ind]
		var prev_module_num = prev_inst.get_meta("module_number")
		match instance.get_meta("module_number"):
			2:
				if prev_module_num == 2:
					instance.get_child(0).visible = false
					prev_inst.get_child(1).visible = false
				elif prev_module_num == 7:
					# View in ground7.tscn how children are ordered
					var back = instance.get_child(0)
					back.scale.y = 0.5
					back.position.x -= 5.0
					var front_old = prev_inst.get_child(3)
					front_old.scale.y = 0.5
					front_old.position.x += 5.0
				elif prev_module_num == 8:
					var back = instance.get_child(0)
					back.scale.y = 0.5
					back.position.x += 5.0
					var front_old = prev_inst.get_child(3)
					front_old.scale.y = 0.5
					front_old.position.x -= 5.0
			3:
				if prev_module_num == 3:
					instance.get_child(0).visible = false
					prev_inst.get_child(1).visible = false
					instance.get_child(2).visible = false
					prev_inst.get_child(3).visible = false
				elif prev_module_num == 4 or prev_module_num == 8:
					instance.get_child(0).visible = false
					prev_inst.get_child(1).visible = false
				elif prev_module_num == 5:
					instance.get_child(2).visible = false
					prev_inst.get_child(1).visible = false
				elif prev_module_num == 7:
					instance.get_child(2).visible = false
					prev_inst.get_child(5).visible = false
			4:
				if prev_module_num == 4:
					instance.get_child(0).visible = false
					prev_inst.get_child(1).visible = false
				elif prev_module_num == 3 || prev_module_num == 8:
					instance.get_child(0).visible = false
					prev_inst.get_child(1).visible = false
			5:
				if prev_module_num == 5:
					instance.get_child(0).visible = false
					prev_inst.get_child(1).visible = false
				elif prev_module_num == 3:
					instance.get_child(0).visible = false
					prev_inst.get_child(3).visible = false
				elif prev_module_num == 7:
					instance.get_child(0).visible = false
					prev_inst.get_child(5).visible = false
			6:
				if prev_module_num == 6:
					instance.get_child(0).visible = false
					prev_inst.get_child(1).visible = false
					instance.get_child(2).visible = false
					prev_inst.get_child(3).visible = false
					instance.get_child(4).visible = false
					prev_inst.get_child(5).visible = false
					instance.get_child(6).visible = false
					prev_inst.get_child(7).visible = false
				elif prev_module_num == 7:
					instance.get_child(0).visible = false
					prev_inst.get_child(1).visible = false
				elif prev_module_num == 8:
					instance.get_child(6).visible = false
					prev_inst.get_child(5).visible = false
			7:
				if prev_module_num == 7:
					instance.get_child(0).visible = false
					prev_inst.get_child(1).visible = false
					instance.get_child(2).visible = false
					prev_inst.get_child(3).visible = false
					instance.get_child(4).visible = false
					prev_inst.get_child(5).visible = false
				elif prev_module_num == 2:
					var back = instance.get_child(2)
					back.scale.y = 0.5
					back.position.x += 5.0
					var front_old = prev_inst.get_child(1)
					front_old.scale.y = 0.5
					front_old.position.x -= 5.0
				elif prev_module_num == 3:
					instance.get_child(4).visible = false
					prev_inst.get_child(3).visible = false
				elif prev_module_num == 5:
					instance.get_child(4).visible = false
					prev_inst.get_child(1).visible = false
				elif prev_module_num == 6:
					instance.get_child(0).visible = false
					prev_inst.get_child(1).visible = false
			8:
				if prev_module_num == 8:
					instance.get_child(0).visible = false
					prev_inst.get_child(1).visible = false
					instance.get_child(2).visible = false
					prev_inst.get_child(3).visible = false
					instance.get_child(4).visible = false
					prev_inst.get_child(5).visible = false
				elif prev_module_num == 2:
					var back = instance.get_child(2)
					back.scale.y = 0.5
					back.position.x -= 5.0
					var front_old = prev_inst.get_child(1)
					front_old.scale.y = 0.5
					front_old.position.x += 5.0
				elif prev_module_num == 3 or prev_module_num == 4:
					instance.get_child(0).visible = false
					prev_inst.get_child(1).visible = false
				elif prev_module_num == 6:
					instance.get_child(4).visible = false
					prev_inst.get_child(7).visible = false
					
	if next_tunnel < TUNNELS.size():
		if n > TUNNELS[next_tunnel]:
			# spawn tunnel
			var tunnel = TUNNEL_SCENE.instantiate()
			tunnel.position.z = n
			tunnels.add_child(tunnel)
			next_tunnel += 1
	add_child(instance)
	module_count += 1
