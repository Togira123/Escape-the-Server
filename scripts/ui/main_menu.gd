extends Control

signal game_start

@onready var player = $"../Player"
@onready var leaderboard = $Leaderboard
@onready var leaderboard_top = $Leaderboard/ScrollContainer
@onready var leaderboard_top_container = $Leaderboard/ScrollContainer/LeaderboardContent
@onready var leaderboard_you_name = $Leaderboard/You
@onready var leaderboard_you_distance = $Leaderboard/DistanceYou
@onready var leaderboard_loading = $Leaderboard/Loading
@onready var leaderboard_resets_in = $Leaderboard/ResetsIn
@onready var settings = $Settings
@onready var shop = $Shop
@onready var help = $Help
@onready var ready_button = $Ready
@onready var not_ready_button = $NotReady
@onready var not_all_players_ready = $NotAllPlayersReady
@onready var season_starting_soon = $SeasonStartingSoon
@onready var you_are_ready = $YouAreReady
@onready var stats_overview = $StatsOverview
@onready var stats = $Stats

@onready var leaderboard_button = $LeaderboardButton
@onready var casual_button = $CasualButton

@onready var settings_check_button = $"Settings/1/CheckButton"
@onready var settings_player_customization = $"Settings/0"
@onready var settings_player_customization_hex_field = $"Settings/0/Hex"
@onready var settings_graphics = $"Settings/2"

@onready var stats_overview_loading = $StatsOverview/Loading
@onready var stats_overview_container = $StatsOverview/GridContainer
@onready var stats_overview_show_all = $StatsOverview/ShowAll

@onready var stats_to_node_path = {
	"micrometers_travelled": ["MicrometersTravelledValue", 0],
	"highest_rank": ["HighestRankValue", 0],
	"shields_obtained": ["ShieldsObtainedValue", -2],
	"teleports_obtained": ["TeleportsObtainedValue", -2],
	"games_started": ["GamesStartedValue", 0],
	"levels_finished": ["LevelsFinishedValue", 0],
	"deaths": ["DeathsValue", 0],
	"longest_distance_ever": ["LongestDistanceEverValue", 1],
	"longest_distance_season": ["LongestDistanceSeasonValue", 1],
	"jumps": ["JumpsValue", 2],
	"rolls": ["RollsValue", 2],
	"spins": ["SpinsValue", 2],
	"teleports_used": ["TeleportsUsedValue", 2],
	"bounced_from_lasers": ["BouncedFromLasersValue", 2],
	"shields_gotten_from_a": ["ShieldsFromAValue", 3],
	"shields_gotten_from_b": ["ShieldsFromBValue", 3],
	"shields_gotten_from_d": ["ShieldsFromDValue", 3],
	"shields_gotten_from_o": ["ShieldsFromOValue", 3],
	"shields_gotten_from_p": ["ShieldsFromPValue", 3],
	"shields_gotten_from_q": ["ShieldsFromQValue", 3],
	"shields_gotten_from_r": ["ShieldsFromRValue", 3],
	"time_in_game": ["TimeInGameValue", 4],
	"time_running": ["TimeRunningValue", 4],
	"all_players_time_in_game": ["AllPlayersTimeInGameValue", 4],
	"all_players_time_running": ["AllPlayersTimeRunningValue", 4],
	"players_revived": ["PlayersRevivedValue", 4],
	"revives_failed": ["RevivesFailedValue", 4],
	"been_revived": ["BeenRevivedValue", 4],
}

var player_icon = null

var not_all_players_ready_timer: SceneTreeTimer = null
var you_are_ready_timer: SceneTreeTimer = null
var season_starting_soon_timer: SceneTreeTimer = null

func _ready():
	if not Client.is_authorized:
		await Client.on_authorize
	else:
		stats_overview_loading.visible = false
		stats_overview_container.visible = true
		stats_overview_show_all.visible = true
	update_play_button()
	settings_check_button.set_pressed_no_signal(Client.settings["default_keybinds"])
	settings._on_check_button_toggled(Client.settings["default_keybinds"], false)
	var player_color = Client.lobby.members[Client.user_id].color
	player.set_color(Color(player_color))
	settings_player_customization_hex_field.text = player_color
	# update settings color wheel but WITHOUT sending a Client.update_user()
	settings_player_customization._on_hex_text_submitted("", false)
	# update graphics settings WITHOUT sending Client.update_settings(), which is why "false" is passed
	if Client.settings["graphics_quality"] == 0:
		settings_graphics._on_radio_low_toggled(true, false)
	else:
		settings_graphics._on_radio_normal_toggled(true, false)
	update_ranked_casual_button()

func _physics_process(_delta: float) -> void:
	if season_starting_soon.visible or leaderboard.visible:
		# new Date((Math.floor(Date.now()/1000/(86400*7))*(86400*7)+388800)*1000).toUTCString()
		var now: int = ceil(Time.get_unix_time_from_system())
		var next_reset = ceil((now - 388800) / (86400 * 7.0)) * (86400 * 7) + 388800
		var seconds: int = next_reset - now
		var minutes: int = 0
		var hours: int = 0
		var days: int = 0
		if seconds >= 60:
			@warning_ignore("integer_division")
			minutes = seconds / 60
			seconds = seconds % 60
		if minutes >= 60:
			@warning_ignore("integer_division")
			hours = minutes / 60
			minutes = minutes % 60
		if hours >= 24:
			@warning_ignore("integer_division")
			days = hours / 24
			hours = hours % 24
		season_starting_soon.text = "Next season starting in: %sd %sh %sm %ss" % [days, hours, minutes, seconds]
		leaderboard_resets_in.text = "Leaderboard resets in: %sd %sh %sm %ss" % [days, hours, minutes, seconds]

func display_not_all_players_ready_message():
	if not_all_players_ready_timer and not_all_players_ready_timer.time_left > 0.0:
		not_all_players_ready_timer.set_time_left(3.0)
	else:
		not_all_players_ready_timer = get_tree().create_timer(3.0, true, false, true)
		not_all_players_ready.visible = true
		await not_all_players_ready_timer.timeout
		not_all_players_ready.visible = false

func display_season_starting_soon_message():
	if season_starting_soon_timer and season_starting_soon_timer.time_left > 0.0:
		season_starting_soon_timer.set_time_left(2.5)
	else:
		season_starting_soon_timer = get_tree().create_timer(3.0, true, false, true)
		season_starting_soon.visible = true
		await season_starting_soon_timer.timeout
		season_starting_soon.visible = false

func update_play_button():
	var user = Client.lobby.members[Client.user_id]
	if Client.user_id == Client.lobby.leader_id or user.gamemode == "ranked":
		$GameStartButton.visible = true
		ready_button.visible = false
		not_ready_button.visible = false
	else:
		$GameStartButton.visible = false
		if user.is_ready:
			ready_button.visible = false
			not_ready_button.visible = true
		else:
			ready_button.visible = true
			not_ready_button.visible = false

func _on_game_start_button_pressed():
	game_start.emit()

func _on_leaderboard_button_pressed():
	Client.set_gamemode("ranked")

func _on_casual_button_pressed():
	Client.set_gamemode("casual")

func update_ranked_casual_button():
	if Client.lobby.members[Client.user_id].gamemode == "ranked":
		# don't need to set seed here because it's set when a run starts
		stats_overview.visible = false
		leaderboard.visible = true
		leaderboard_button.visible = false
		casual_button.visible = true
	else: # gamemode is casual
		leaderboard.visible = false
		stats_overview.visible = true
		casual_button.visible = false
		leaderboard_button.visible = true
		Client.ranked_rand.randomize()
		Client.ranked_rand_drop.randomize()

func _on_settings_button_pressed():
	stats_overview.visible = false
	leaderboard.visible = false
	settings.visible = true
	settings.call_deferred("grab_focus")
	$TransparentBg.visible = true

func _on_shop_button_pressed():
	settings.visible = false
	shop.visible = true
	await get_tree().create_timer(3.0).timeout
	shop.visible = false

func _on_help_button_pressed():
	stats_overview.visible = false
	leaderboard.visible = false
	help.visible = true
	help.call_deferred("grab_focus")
	$TransparentBg.visible = true

func _on_show_all_pressed():
	stats_overview.visible = false
	leaderboard.visible = false
	stats.visible = true
	stats.call_deferred("grab_focus")
	$TransparentBg.visible = true

func _on_transparent_bg_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if help.visible:
			help.close()
			if Client.lobby.members[Client.user_id].gamemode == "ranked":
				leaderboard.visible = true
			else:
				stats_overview.visible = true
		elif settings.visible:
			settings.close()
			if Client.lobby.members[Client.user_id].gamemode == "ranked":
				leaderboard.visible = true
			else:
				stats_overview.visible = true
		elif stats.visible:
			stats.close()
			if Client.lobby.members[Client.user_id].gamemode == "ranked":
				leaderboard.visible = true
			else:
				stats_overview.visible = true

func _on_ready_pressed():
	Client.set_ready(true)
	ready_button.visible = false
	not_ready_button.visible = true
	if not player_icon:
		player_icon = get_node("../Level/UI/Players/" + Client.user_id)
	player_icon.get_node("Ready").visible = true
	player_icon.get_node("NotReady").visible = false

	you_are_ready.size.x = 300
	you_are_ready.position.x = 810
	you_are_ready.text = "You are ready"
	if you_are_ready_timer and you_are_ready_timer.time_left > 0.0:
		you_are_ready_timer.set_time_left(2.0)
	else:
		you_are_ready_timer = get_tree().create_timer(2.0, true, false, true)
		you_are_ready.visible = true
		await you_are_ready_timer.timeout
		you_are_ready.visible = false

func _on_not_ready_pressed():
	Client.set_ready(false)
	ready_button.visible = true
	not_ready_button.visible = false
	if not player_icon:
		player_icon = get_node("../Level/UI/Players/" + Client.user_id)
	player_icon.get_node("Ready").visible = false
	player_icon.get_node("NotReady").visible = true

	you_are_ready.size.x = 370
	you_are_ready.position.x = 775
	you_are_ready.text = "You are not ready"
	if you_are_ready_timer and you_are_ready_timer.time_left > 0.0:
		you_are_ready_timer.set_time_left(2.0)
	else:
		you_are_ready_timer = get_tree().create_timer(2.0, true, false, true)
		you_are_ready.visible = true
		await you_are_ready_timer.timeout
		you_are_ready.visible = false

func mode_to_node_name(mode: String):
	match mode:
		"singleplayer":
			return "Single"
		"multiplayer":
			return "Multi"
		"ranked":
			return "Ranked"

func update_stats():
	for mode in Client.stats:
		for stat in Client.stats[mode]:
			var node_name = stats_to_node_path[stat][0]
			var node_num = stats_to_node_path[stat][1]
			match node_num:
				-2, 2:
					var node = get_node("Stats/1/GridContainer/" + node_name + mode_to_node_name(mode))
					node.text = Client.stats[mode][stat]
				0, 1:
					var node = get_node("Stats/0/GridContainer/" + node_name + mode_to_node_name(mode))
					var value = Client.stats[mode][stat]
					if stat == "highest_rank":
						if mode == "ranked":
							if value > 1000000000000:
								value = "None"
							elif value > 500:
								value = ">500"
							else:
								value = "#" + str(value)
						else:
							continue
					node.text = value
	# another iteration for "total"
	for stat in Client.stats["singleplayer"]:
		var node_name = stats_to_node_path[stat][0]
		var node_num = stats_to_node_path[stat][1]
		match node_num:
			-2:
				var node = get_node("StatsOverview/GridContainer/" + node_name)
				node.text = Client.stats["singleplayer"][stat] + Client.stats["multiplayer"][stat] + Client.stats["ranked"][stat]
				var node2 = get_node("Stats/1/GridContainer/" + node_name + "Total")
				node2.text = node.text
			0:
				var node = get_node("StatsOverview/GridContainer/" + node_name)
				var node2 = get_node("Stats/0/GridContainer/" + node_name + "Total")
				if stat == "highest_rank":
					var value = Client.stats["ranked"][stat]
					if value > 1000000000000:
						value = "None"
					elif value > 500:
						value = ">500"
					else:
						value = "#" + str(value)
					node.text = value
				else:
					node.text = Client.stats["singleplayer"][stat] + Client.stats["multiplayer"][stat] + Client.stats["ranked"][stat]
					node2.text = node.text
			1:
				var node = get_node("Stats/0/GridContainer/" + node_name + "Total")
				node.text = Client.stats["singleplayer"][stat] + Client.stats["multiplayer"][stat] + Client.stats["ranked"][stat]
			2:
				var node = get_node("Stats/1/GridContainer/" + node_name + "Total")
				node.text = Client.stats["singleplayer"][stat] + Client.stats["multiplayer"][stat] + Client.stats["ranked"][stat]
			3:
				var node = get_node("Stats/2/GridContainer/" + node_name + "Total")
				node.text = Client.stats["singleplayer"][stat] + Client.stats["multiplayer"][stat] + Client.stats["ranked"][stat]
			4:
				var node = get_node("Stats/2/GridContainer2/" + node_name + "Total")
				if node_name.contains("Time"):
					var seconds: int = Client.stats["singleplayer"][stat] + Client.stats["multiplayer"][stat] + Client.stats["ranked"][stat]
					var minutes: int = 0
					var hours: int = 0
					var days: int = 0
					if seconds >= 60:
						@warning_ignore("integer_division")
						minutes = seconds / 60
						seconds = seconds % 60
					if minutes >= 60:
						@warning_ignore("integer_division")
						hours = minutes / 60
						minutes = minutes % 60
					if hours >= 24:
						@warning_ignore("integer_division")
						days = hours / 24
						hours = hours % 24
					node.text = "%sd %sh %sm %ss" % [days, hours, minutes, seconds]
				else:
					node.text = Client.stats["singleplayer"][stat] + Client.stats["multiplayer"][stat] + Client.stats["ranked"][stat]
	if stats_overview_loading.visible:
		stats_overview_loading.visible = false
		stats_overview_container.visible = true
		stats_overview_show_all.visible = true

func update_leaderboard():
	var count = 1
	for user in Client.leaderboard["top"]:
		var label_name = Label.new()
		label_name.name = str(count)
		label_name.text = ("#0" if count < 10 else "#") + str(count) + " | " + user.global_name
		label_name.add_theme_font_size_override("font_size", 30)
		label_name.size = Vector2(290, 41)
		label_name.position = Vector2(0, 71 * (count - 1))
		label_name.clip_text = true
		label_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		var label_distance = Label.new()
		label_distance.name = "Distance" + str(count)
		label_distance.text = str(user.longest_distance_season) + " μm"
		label_distance.add_theme_font_size_override("font_size", 30)
		label_distance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label_distance.size = Vector2(177, 41)
		label_distance.position = Vector2(300, 71 * (count - 1))
		label_distance.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		leaderboard_top_container.add_child(label_name)
		leaderboard_top_container.add_child(label_distance)
		count += 1
	if Client.leaderboard["you"].rank:
		leaderboard_you_name.text = ("#0" if Client.leaderboard["you"].rank < 10 else "#") + str(Client.leaderboard["you"].rank) + " | You"
		leaderboard_you_distance.text = Client.leaderboard["you"].longest_distance_season
	else:
		leaderboard_you_name.text = "#>500 | You"
		leaderboard_you_distance.text = str(Client.leaderboard["you"].longest_distance_season) + " μm"
	leaderboard_you_name.visible = true
	leaderboard_you_distance.visible = true
	leaderboard_top_container.custom_minimum_size = Vector2(485, 71 * (count - 1))
	leaderboard_loading.visible = false
	leaderboard_top.visible = true
	leaderboard_resets_in.visible = true
