extends Node3D

@export var modules: Array[PackedScene] = []
var loaded_modules = []
var amount = 10
var rng = RandomNumberGenerator.new()
const OFFSET: int = 20
const LOADED_MODULES_SIZE: int = 32
var module_count: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	loaded_modules.resize(LOADED_MODULES_SIZE)
	for n in amount:
		spawn_module(module_count * OFFSET)


func spawn_module(n: int):
	var instance = modules[0].instantiate()
	instance.position.z = n - OFFSET * 5
	var index: int = (n / OFFSET) % LOADED_MODULES_SIZE;
	if loaded_modules[index]:
		loaded_modules[index].queue_free()
	loaded_modules[index] = instance
	add_child(instance)
	var activate_index = (index + 15) % LOADED_MODULES_SIZE;
	if loaded_modules[activate_index] and not loaded_modules[activate_index].has_dropped:
		loaded_modules[activate_index].drop_letters()
	module_count += 1
