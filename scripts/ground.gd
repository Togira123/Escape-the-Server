extends Node3D

@export var letter_scenes: Array[PackedScene] = []

@onready var constants = $"../../Constants"

@onready var letter_dict = {
	"A": letter_scenes[0],
	"B": letter_scenes[1],
	"C": letter_scenes[2],
	"D": letter_scenes[3],
	"E": letter_scenes[4],
	"F": letter_scenes[5],
	"G": letter_scenes[6],
	"H": letter_scenes[7],
	"I": letter_scenes[8],
	"J": letter_scenes[9],
	"K": letter_scenes[10],
	"L": letter_scenes[11],
	"M": letter_scenes[12],
	"N": letter_scenes[13],
	"O": letter_scenes[14],
	"P": letter_scenes[15],
	"Q": letter_scenes[16],
	"R": letter_scenes[17],
	"S": letter_scenes[18],
	"T": letter_scenes[19],
	"U": letter_scenes[20],
	"V": letter_scenes[21],
	"W": letter_scenes[22],
	"X": letter_scenes[23],
	"Y": letter_scenes[24],
	"Z": letter_scenes[25]
}

@onready var sentence_node = $Sentence

var spawned_letters = []
var has_dropped = false

# Called when the node enters the scene tree for the first time.
func _ready():
	if (randi() % 4) != 1:
		return
	var letter_scale = (randi() % 4) + 5
	var scale_vec = Vector3(letter_scale, letter_scale, letter_scale)
	var sentence = constants.get_random_sentence().to_upper()
	var rotation_y = (40 - (randi() % 80)) * (PI / 180.0)
	sentence_node.rotation.y = rotation_y
	var cur_x_pos = len(sentence) * letter_scale
	for i in range(len(sentence)):
		if sentence[i] == " ":
			cur_x_pos -= letter_scale * 1.5
			continue
		if not letter_dict.has(sentence[i]):
			continue
		var letter = letter_dict[sentence[i]]
		var instance = letter.instantiate()
		instance.get_node("Pivot").scale = scale_vec
		instance.get_node("Hitbox").scale = scale_vec
		instance.get_node("GroundCollisionDetector").scale = scale_vec
		var width = abs(instance.get_node("Pivot/MeshInstance3D").get_aabb().size.x)
		
		instance.position.x = cur_x_pos
		cur_x_pos -= width * letter_scale + 3
		instance.position.y = 20
		instance.rotation.y = PI
		instance.freeze = true
		spawned_letters.append(instance)
		sentence_node.add_child(instance)

func drop_letters():
	has_dropped = true
	for inst in spawned_letters:
		inst.freeze = false
