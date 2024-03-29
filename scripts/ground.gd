extends Node3D

@export var letter_scenes: Array[PackedScene] = []

var spawned_letters = []

# Called when the node enters the scene tree for the first time.
func _ready():
	var letter = letter_scenes[randi() % letter_scenes.size()]
	var instance = letter.instantiate()
	instance.position.y = 20
	instance.rotation.y = PI
	instance.freeze = true
	spawned_letters.append(instance)
	add_child(instance)

func drop_letters():
	for inst in spawned_letters:
		inst.freeze = false
