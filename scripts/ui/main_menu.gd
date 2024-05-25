extends Control

signal game_start

@onready var player = $"../Player"
@onready var leaderboard = $Leaderboard
@onready var settings = $Settings
@onready var shop = $Shop
@onready var help = $Help
@onready var ready_button = $Ready
@onready var not_ready_button = $NotReady
@onready var not_all_players_ready = $NotAllPlayersReady
@onready var you_are_ready = $YouAreReady
@onready var stats_overview = $StatsOverview
@onready var stats = $Stats

@onready var settings_check_button = $"Settings/1/CheckButton"
@onready var settings_player_customization = $"Settings/0"
@onready var settings_player_customization_hex_field = $"Settings/0/Hex"
@onready var settings_graphics = $"Settings/2"
var player_icon = null

var not_all_players_ready_timer: SceneTreeTimer = null
var you_are_ready_timer: SceneTreeTimer = null

func _ready():
	if not Client.is_authorized:
		await Client.on_authorize
	update_play_button(true)
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

func display_not_all_players_ready_message():
	if not_all_players_ready_timer and not_all_players_ready_timer.time_left > 0.0:
		not_all_players_ready_timer.set_time_left(3.0)
	else:
		not_all_players_ready_timer = get_tree().create_timer(3.0, true, false, true)
		not_all_players_ready.visible = true
		await not_all_players_ready_timer.timeout
		not_all_players_ready.visible = false

func update_play_button(initial: bool):
	if Client.user_id == Client.lobby.leader_id:
		$GameStartButton.visible = true
		ready_button.visible = false
		not_ready_button.visible = false
	elif initial:
		ready_button.visible = true


func _on_game_start_button_pressed():
	game_start.emit()

func _on_leaderboard_button_pressed():
	settings.visible = false
	shop.visible = false
	leaderboard.visible = true
	await get_tree().create_timer(3.0).timeout
	leaderboard.visible = false

func _on_settings_button_pressed():
	stats_overview.visible = false
	settings.visible = true
	settings.call_deferred("grab_focus")
	$TransparentBg.visible = true

func _on_shop_button_pressed():
	settings.visible = false
	leaderboard.visible = false
	shop.visible = true
	await get_tree().create_timer(3.0).timeout
	shop.visible = false

func _on_help_button_pressed():
	stats_overview.visible = false
	help.visible = true
	help.call_deferred("grab_focus")
	$TransparentBg.visible = true

func _on_show_all_pressed():
	stats_overview.visible = false
	stats.visible = true
	stats.call_deferred("grab_focus")
	$TransparentBg.visible = true

func _on_transparent_bg_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if help.visible:
			help.close()
			stats_overview.visible = true
		elif settings.visible:
			settings.close()
			stats_overview.visible = true
		elif stats.visible:
			stats.close()
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
