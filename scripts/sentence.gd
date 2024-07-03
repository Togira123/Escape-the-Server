extends Node3D

@export var letter_scenes: Array[PackedScene] = []

@onready var constants = $"../../Constants"
@onready var level = $"../../Level"
@onready var player = $"../../Player"

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

const LETTER_SCALE = 7

var spawned_letters: Array[Node] = []
var drop_at_z = 9223372036854775807
var dropped = false
# stores x coord of built things
var built_at: Array[int] = []
static var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Called when the node enters the scene tree for the first time.
func _ready():
	set_physics_process(false)
	if position.z > constants.next_sentence_position_z:
		spawn_sentence()

func spawn_sentence():
	var sentence = constants.get_random_sentence().to_upper()
	var cur_x_pos = len(sentence) * LETTER_SCALE + (50 - (Client.ranked_rand.randi() % 100))
	var height = (Client.ranked_rand.randi() % 30) * 2 + 40
	for i in range(len(sentence)):
		if sentence[i] == " ":
			cur_x_pos -= LETTER_SCALE * 1.5
			continue
		if not letter_dict.has(sentence[i]):
			continue
		var letter = letter_dict[sentence[i]]
		var instance = letter.instantiate()
		var width = abs(instance.get_node("Pivot/MeshInstance3D").get_aabb().size.x) * LETTER_SCALE

		instance.position.x = cur_x_pos - width / 2
		cur_x_pos -= width + 2
		instance.position.y = height
		instance.rotation.y = PI + ((8 - (Client.ranked_rand.randi() % 16)) * (PI / 180.0))
		if Client.ranked_rand.randi() % 4 == 0:
			instance.rotation.x += (4 - (Client.ranked_rand.randi() % 8)) * (PI / 180.0)
		instance.freeze = true
		spawned_letters.append(instance)
		sentence_node.add_child(instance)
	if Client.ranked_rand.randi() % 10 == 1:
		drop_at_z = constants.next_sentence_position_z + 10000
	else:
		drop_at_z = int(constants.next_sentence_position_z - (sqrt(2*height/9.8)) * player.speed) - player.speed - 40 + (40 - (Client.ranked_rand.randi() % 20))
		if player.build_only:
			if constants.up:
				drop_at_z += 100
				constants.up = false
			else:
				constants.up = true

	if level.next_tunnel >= level.TUNNELS.size():
		constants.next_sentence_position_z += 10000
	elif level.get_next_tunnel() < constants.next_sentence_position_z + 150:
		constants.next_sentence_position_z = level.get_next_tunnel() + level.TUNNEL_LENGTH + 150
	else:
		#constants.next_sentence_position_z += 120 if player.spawn_platforms and not player.build_only else 60
		constants.next_sentence_position_z += 40 if player.build_only else (120 if player.spawn_platforms else 60)

func maybe_drop(pos):
	if pos > drop_at_z and not dropped:
		dropped = true
		var count = 0
		shuffle(spawned_letters)
		for inst in spawned_letters:
			inst.freeze = false
			if count % 4 == 0:
				await get_tree().create_timer(0.1).timeout
			count += 1
		set_physics_process(true)

func change_color_of_pattern():
	if has_node("Ground"):
		var shader: ShaderMaterial = $Ground/Pattern.mesh.surface_get_material(0)
		shader.set_shader_parameter("progress", constants.ground_pattern_color_change_progress)
		shader.set_shader_parameter("emit", 3 + constants.ground_pattern_color_change_progress * 3)

func shuffle(array: Array):
	var n = array.size()
	for i in range(n - 1):
		var j = Client.ranked_rand_drop.randi_range(i, n - 1)
		var t = array[i]
		array[i] = array[j]
		array[j] = t
