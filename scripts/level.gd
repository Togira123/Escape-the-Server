extends Node3D

const SHORT_LASER_PIVOT = preload("res://scenes/lasers/laser_pivot_short.tscn")
const TUNNEL_SCENE = preload("res://scenes/tunnel.tscn")
const OFFSET: int = 20
const LOADED_MODULES_SIZE: int = 32
const TUNNELS = [300, 1900, 10000]
const TUNNEL_LENGTH = 500

@onready var tunnels = $"Tunnels"
@export var modules: Array[PackedScene] = []
@export var platform_modules1: Array[PackedScene] = [] # groups 1 and 2
@export var platform_modules2: Array[PackedScene] = [] # groups 2 and 3
@export var platform_modules3: Array[PackedScene] = [] # groups 3 and 1
var loaded_modules = []
var amount = LOADED_MODULES_SIZE

var next_tunnel = 0

var module_count: int = 0

var stage = 0

var skip = false # used to only place a platform module every second time
var last_group = 3

# Called when the node enters the scene tree for the first time.
func _ready():
	loaded_modules.resize(LOADED_MODULES_SIZE)
	for n in amount:
		spawn_module(module_count * OFFSET, false)

func spawn_module(n: int, platforms: bool):
	var index: int = (n / OFFSET) % LOADED_MODULES_SIZE
	var prev_ind = LOADED_MODULES_SIZE - 1 if index == 0 else index - 1
	var instance
	if platforms:
		if not skip:
			var mod
			match last_group:
				3:
					mod = platform_modules1[(randi() % (platform_modules1.size() - 1)) + 1]
				1:
					mod = platform_modules2[(randi() % (platform_modules2.size() - 1)) + 1]
				2:
					mod = platform_modules3[(randi() % (platform_modules3.size() - 1)) + 1]
			instance = mod.instantiate()
			instance.position.z = n
			if loaded_modules[index]:
				loaded_modules[index].queue_free()
			# duplicate floor
			var instance2 = mod.instantiate()
			instance2.position.z = n + OFFSET
			var next_index = 0 if index == LOADED_MODULES_SIZE - 1 else index + 1
			if loaded_modules[next_index]:
				loaded_modules[next_index].queue_free()
			loaded_modules[next_index] = instance2
			
			# instance.name is ModulePlat1, ModulePlat2 etc
			print(instance.name)
			print(instance2.name)
			match instance.name:
				&"ModulePlat1", &"ModulePlat2":
					last_group = 1
					instance2.get_child(0).visible = false
					instance2.get_child(2).visible = false
					instance2.get_child(4).visible = false
					instance.get_child(1).visible = false
					instance.get_child(3).visible = false
					instance.get_child(5).visible = false
				&"ModulePlat3":
					last_group = 2
					instance2.get_child(0).visible = false
					instance2.get_child(2).visible = false
					instance.get_child(1).visible = false
					instance.get_child(3).visible = false
				&"ModulePlat4", &"ModulePlat5":
					last_group = 3
					instance2.get_child(0).visible = false
					instance2.get_child(2).visible = false
					instance2.get_child(4).visible = false
					instance.get_child(1).visible = false
					instance.get_child(3).visible = false
					instance.get_child(5).visible = false
			
			add_child(instance2)
			module_count += 1
			skip = true
		else:
			skip = false
			return
	else:
		instance = modules[0 if n < 10 * OFFSET or (next_tunnel > 0 and n >= TUNNELS[next_tunnel - 1] - 3 * OFFSET and n <= TUNNELS[next_tunnel - 1] + 26 * OFFSET) else randi() % modules.size()].instantiate()
		instance.position.z = n
		if loaded_modules[index]:
			loaded_modules[index].queue_free()
		# add lasers if stage > 0
		if stage > 1:
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
						
	loaded_modules[index] = instance
	if next_tunnel < TUNNELS.size():
		if n > TUNNELS[next_tunnel]:
			# spawn tunnel
			var count = 5 if next_tunnel == TUNNELS.size() - 1 else 2
			for i in range(count):
				var tunnel = TUNNEL_SCENE.instantiate()
				tunnel.position.z = n + i * 250
				tunnels.add_child(tunnel)
			next_tunnel += 1
	add_child(instance)
	module_count += 1
