extends Node3D

@export var letter_scenes: Array[PackedScene] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	var letter = letter_scenes[randi() % letter_scenes.size()]
	var instance = letter.instantiate()
	instance.position.y = 20
	add_child(instance)
