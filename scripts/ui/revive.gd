extends Control

const BUTTON_SIZE = 200
const BUTTON_SPACE = 50

const TIME_TO_SOLVE = 2.5

const PROGRESS_BAR_SIZE = 1200.0

@onready var keys_parent_node = $Keys
@onready var progress_bar = $ProgressBar
@onready var message = $Message

var width = ProjectSettings.get_setting("display/window/size/viewport_width")

@export var keys: Array[PackedScene] = [] # down, left, right, up

var key_indexes: Array[int] = []
var cur_key = 0

# stage is the stage the player died in
var stage: int
var target_user_id: String

var disappear_timer: SceneTreeTimer = null
var time_to_solve_timer: SceneTreeTimer = null

# Called when the node enters the scene tree for the first time.
func _ready():
	cur_key = 0
	var number_of_buttons = stage + 4
	var x_pos = (width - BUTTON_SIZE * number_of_buttons - BUTTON_SPACE * number_of_buttons - 1) / 2.0
	var y_pos = 300
	message.text = "Revive " + Client.lobby.members[target_user_id].username + "!"
	for i in range(number_of_buttons):
		var index = randi() % keys.size()
		var key = keys[index]
		key_indexes.append(index)
		var key_scene: TextureRect = key.instantiate()
		key_scene.position.x = x_pos + i * (BUTTON_SPACE + BUTTON_SIZE)
		key_scene.position.y = y_pos
		keys_parent_node.add_child(key_scene)
	# give time to solve, afterwards start disappearing
	time_to_solve_timer = get_tree().create_timer(TIME_TO_SOLVE, true, false, true)
	await time_to_solve_timer.timeout
	start_disappear_timer("")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("revive_down"):
		if key_indexes[cur_key] == 0:
			clicked_correct()
		else:
			clicked_wrong()
	if Input.is_action_just_pressed("revive_left"):
		if key_indexes[cur_key] == 1:
			clicked_correct()
		else:
			clicked_wrong()
	if Input.is_action_just_pressed("revive_right"):
		if key_indexes[cur_key] == 2:
			clicked_correct()
		else:
			clicked_wrong()
	if Input.is_action_just_pressed("revive_up"):
		if key_indexes[cur_key] == 3:
			clicked_correct()
		else:
			clicked_wrong()

# only used to animate the progress bar
func _physics_process(_delta):
	progress_bar.size.x = time_to_solve_timer.time_left / TIME_TO_SOLVE * PROGRESS_BAR_SIZE

# revived_by_user_id is an empty string if reviving failed
func start_disappear_timer(revived_by_user_id: String):
	set_process(false)
	if not disappear_timer:
		# no disappear timer set yet
		disappear_timer = get_tree().create_timer(1.0, true, false, true)
		var color = Color(0.0, 2.0, 0.0, 1.0) if revived_by_user_id == Client.user_id else Color("26d8cd")
		if revived_by_user_id != "":
			message.text = "Revived by " + Client.lobby.members[revived_by_user_id].username + "!"
		else:
			color = Color(2.0, 0.1, 0.0, 1.0)
			message.text = "Failed to revive!"
		message.modulate = color
		for i in range(key_indexes.size()):
			keys_parent_node.get_child(i).modulate = color
		await disappear_timer.timeout
		queue_free()

func clicked_correct():
	keys_parent_node.get_child(cur_key).modulate = Color(0.0, 2.0, 0.0, 1.0)
	if cur_key == key_indexes.size() - 1:
		# clicked the last key correctly, revive player
		Client.send_revive(target_user_id)
		# the response of the server will trigger start_disappear_timer, no need to call it here
	else:
		cur_key += 1

func clicked_wrong():
	keys_parent_node.get_child(cur_key).modulate = Color(2.0, 0.0, 0.0, 1.0)
	var old_key = cur_key
	cur_key = 0
	for i in range(old_key):
		keys_parent_node.get_child(i).modulate = Color(1.0, 1.0, 1.0, 1.0)
	await get_tree().create_timer(0.5, true, false, true).timeout
	if keys_parent_node.get_child(old_key).modulate == Color(2.0, 0.0, 0.0, 1.0):
			keys_parent_node.get_child(old_key).modulate = Color(1.0, 1.0, 1.0, 1.0)
