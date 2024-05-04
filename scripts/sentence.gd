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

var spawned_letters: Array[Node] = []
var frozen_letters: Array[Node] = []
var frozen_letters_vel = 0.0
var drop_at_z = position.z + 100000
var dropped = false
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Called when the node enters the scene tree for the first time.
func _ready():
	set_physics_process(false)
	if position.z > constants.next_sentence_position_z:
		spawn_sentence()

func _physics_process(delta):
	frozen_letters_vel += gravity * delta
	for letter in frozen_letters:
		letter.position.y -= frozen_letters_vel * delta

func spawn_sentence():
	var letter_scale = (randi() % 4) + 5
	var scale_vec = Vector3(letter_scale, letter_scale, letter_scale)
	var sentence = constants.get_random_sentence().to_upper()
	var rotation_y = (40 - (randi() % 80)) * (PI / 180.0)
	var cur_x_pos = len(sentence) * letter_scale + (50 - (randi() % 100))
	var height = (randi() % 30) * 2 + 40
	for i in range(len(sentence)):
		if sentence[i] == " ":
			cur_x_pos -= letter_scale * 1.5
			continue
		if not letter_dict.has(sentence[i]):
			continue
		var letter = letter_dict[sentence[i]]
		var instance = letter.instantiate()
		# always scale the texture
		instance.get_node("Pivot").scale = scale_vec
		var width = abs(instance.get_node("Pivot/MeshInstance3D").get_aabb().size.x) * letter_scale
		
		instance.position.x = cur_x_pos - width / 2
		if abs(instance.position.x) > 120:
			instance.get_node("LetterHitbox").queue_free()
			instance.get_node("GroundCollisionDetector").queue_free()
			if instance.has_node("ShieldHitbox"):
				instance.get_node("ShieldHitbox").queue_free()
			frozen_letters.append(instance)
		else:
			instance.get_node("LetterHitbox").scale = scale_vec
			instance.get_node("GroundCollisionDetector").scale = scale_vec
			if instance.has_node("ShieldHitbox"):
				instance.get_node("ShieldHitbox").scale = scale_vec
		cur_x_pos -= width + 2
		instance.position.y = height
		instance.rotation.y = PI
		instance.freeze = true
		spawned_letters.append(instance)
		sentence_node.add_child(instance)
	if randi() % 10 == 1:
		drop_at_z = constants.next_sentence_position_z + 10000
	else:
		drop_at_z = (constants.next_sentence_position_z - (sqrt(2*height/9.8)) * player.speed) - player.speed - 40 + (40 - (randi() % 20))
	
	if level.next_tunnel >= level.TUNNELS.size():
		constants.next_sentence_position_z += 10000
	elif level.TUNNELS[level.next_tunnel] < constants.next_sentence_position_z + 150:
		constants.next_sentence_position_z = level.TUNNELS[level.next_tunnel] + level.TUNNEL_LENGTH + 150
	else:
		constants.next_sentence_position_z += 60 if not player.spawn_platforms else 120

func maybe_drop(pos):
	if pos > drop_at_z and not dropped:
		var count = 0
		spawned_letters.shuffle()
		for inst in spawned_letters:
			if abs(inst.position.x) <= 120:
				inst.freeze = false
			else:
				if count % 4 == 0:
					await get_tree().create_timer(0.1).timeout
				count += 1
		dropped = true
		set_physics_process(true)

func change_color_of_pattern():
	if has_node("Ground"):
		var shader: ShaderMaterial = $Ground/Pattern.mesh.surface_get_material(0)
		shader.set_shader_parameter("progress", constants.ground_pattern_color_change_progress)
		shader.set_shader_parameter("emit", 3 + constants.ground_pattern_color_change_progress * 3)
	
