extends CharacterBody3D

@onready var armature = $Armature
@onready var animation_tree = $AnimationTree
@onready var state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")

@onready var name_tag = $NameTag

const WALK_SPEED = 1.5 * 60
const LERP_VAL = 0.3

# used to walk to player around randomly in lobby
var arrived = false
var x = 6 - (randi() % 12)
var z = 3 - (randi() % 6)

var user_id: String # is set in the client.gd script if it's another player

func _ready():
	set_process(false)
	if not Client.is_authorized:
		await Client.on_authorize
	if user_id and user_id.length() > 0:
		name_tag.text = Client.lobby.members[user_id].global_name
	else:
		name_tag.text = Client.lobby.members[Client.user_id].global_name
	name_tag.visible = true

func _physics_process(delta):
	# walk user around randomly in lobby
	if arrived:
		# make sure not same numbers as before are picked
		var prev_x = x
		var prev_z = z
		while true:
			x = 6 - (randi() % 12)
			z = 3 - (randi() % 6)
			if prev_x != x or prev_z != z:
				break
		set_physics_process(false)
		await get_tree().create_timer(randi() % 3 + 1, true, true).timeout
		set_physics_process(true)
		arrived = false
	else:
		arrived = move_to_random_point(x, z, delta)

func move_to_random_point(x, z, delta):
	if abs(position.x - x) < 0.2 or abs(position.z - z) < 0.2:
		state_machine.travel("idle")
		return true
	if state_machine.get_current_node() != "walk":
		state_machine.travel("walk")
	var target = Vector3(x, position.y, z)
	var direction = target - position
	direction = direction.normalized()
	velocity.x = direction.x * WALK_SPEED * delta
	velocity.z = direction.z * WALK_SPEED * delta
	armature.rotation.y = lerp_angle(armature.rotation.y, atan2(velocity.x, velocity.z), LERP_VAL / 2)
	move_and_slide()
	return false
