extends Node

const LOADING_SCREEN = preload("res://scenes/ui/loading_screen.tscn")
const CONNECTING_TO_SERVER_SCREEN = preload("res://scenes/ui/connecting_to_server.tscn")
const END_MENU_DEFEAT = preload("res://scenes/ui/end_menu_defeat.tscn")
const END_MENU_VICTORY = preload("res://scenes/ui/end_menu_victory.tscn")

@onready var player_camera = $PlayerCamera
@onready var player = $Player
@onready var player_soul = $Player/PlayerSoul
@onready var mesh = $Player/Armature/Skeleton3D/Skin
@onready var level = $Level

var in_level = false

var start_running = true
var move_camera_down = true

var game_over = false
# black screen at the end of the game
var black_screen: ColorRect

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(false)
	if Client.is_authorized:
		Client.return_to_menu()
		Client.request_stats()
		Client.request_lb()
	else:
		Input.set_use_accumulated_input(false)
		add_child(CONNECTING_TO_SERVER_SCREEN.instantiate())
		Client.init()
		await Client.on_authorize
		Client.request_stats()
		Client.request_lb()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if game_over:
		var col = black_screen.get_color().a;
		if col >= 1.0:
			Engine.set_time_scale(1.0)
			black_screen.queue_free()
			$Level/UI.visible = false
			var stats_to_update = {
				"jumps": player.jump_count,
				"rolls": player.roll_count,
				"spins": player.spin_count,
				"teleports_obtained": player.teleports_obtained,
				"teleports_used": player.teleports_used,
				"bounced_from_lasers": player.laser_bounce_count
			}
			var total_shields = 0
			for k: String in player.shield_count:
				if player.shield_count[k] > 0:
					stats_to_update["shields_gotten_from_" + k.to_lower()] = player.shield_count[k]
					total_shields += player.shield_count[k]
			if total_shields > 0:
				stats_to_update["shields_obtained"] = total_shields
			if player.player_state == player.State.FINISHED:
				# player has won
				var end_menu = END_MENU_VICTORY.instantiate()
				add_child(end_menu)
				stats_to_update["levels_finished"] = 1
				stats_to_update["micrometers_travelled"] = level.TUNNELS[level.TUNNELS.size() - 1]
			else:
				# player died
				var end_menu = END_MENU_DEFEAT.instantiate()
				add_child(end_menu)
				stats_to_update["micrometers_travelled"] = round(player.position.z)
			Client.update_stats(stats_to_update)
			set_process(false)
		black_screen.set_color(Color(0, 0, 0, clamp(col + delta, 0.0, 1.0)))
		return
	if not start_running and not move_camera_down:
		set_process(false)
		return
	if start_running and not player.start_running(delta):
		start_running = false
	if move_camera_down and not player_camera.move_camera_down(delta):
		move_camera_down = false

func restart_game():
	# make sure floor looks the same again
	$Constants.ground_pattern_color_change_progress = 0
	player_soul.get_tree().call_group("module", "change_color_of_pattern")
	get_tree().reload_current_scene()
	player_soul.mesh.material.set_shader_parameter("turned_on", false)
	mesh.material_override.set_shader_parameter("dissolve_amount", 0.0)
	$Level/UI/HeatEffect.material.set_shader_parameter("alpha", 0.0)
	# make sure time scale is back to normal
	Engine.set_time_scale(1.0)

func _on_main_menu_game_start():
	# send START_GAME to all of the lobby
	Client.leader_start_game()

# called in client.gd when GAME_START message is received
func start_game():
	if Client.lobby.members[Client.user_id].gamemode == "ranked":
		Client.ranked_rand.set_seed(Client.ranked_seed)
		Client.ranked_rand_drop.set_seed(Client.ranked_seed)
		level.TUNNELS = level.RANKED_TUNNELS
	else:
		level.TUNNELS = level.CASUAL_TUNNELS
	set_process(true)
	# remove main menu from scene tree
	$MainMenu.queue_free()
	in_level = true
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	for player_icon in $"Level/UI/Players/".get_children():
		player_icon.get_node("Ready").visible = false
		player_icon.get_node("NotReady").visible = false
		player_icon.get_node("Leader").visible = false
		player_icon.get_node("Dead").visible = false
		player_icon.get_node("Running").visible = false
		player_icon.get_node("Lobby").visible = false
	# call this to load the first few modules (besides the default ones)
	level.load_level_start_on_game_start()
	if Client.lobby.members[Client.user_id].gamemode == "ranked":
		level.get_node("UI/Materials").visible = true

func _on_player_game_over(skip_animation: bool):
	var ins = LOADING_SCREEN.instantiate()
	black_screen = ins.get_child(0)
	black_screen.set_color(Color(0, 0, 0, 1 if skip_animation else 0))
	game_over = true
	add_child(ins)
	set_process(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
