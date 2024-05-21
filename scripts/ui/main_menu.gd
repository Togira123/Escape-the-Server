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

@onready var settings_check_button = $"Settings/1/CheckButton"
@onready var settings_player_customization = $"Settings/0"
@onready var settings_player_customization_hex_field = $"Settings/0/Hex"
var player_icon = null

var not_all_players_ready_timer: SceneTreeTimer = null

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
	help.visible = true
	help.call_deferred("grab_focus")
	$TransparentBg.visible = true

func _on_transparent_bg_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if help.visible:
			help.close()
		elif settings.visible:
			settings.close()

func _on_ready_pressed():
	Client.set_ready(true)
	ready_button.visible = false
	not_ready_button.visible = true
	if not player_icon:
		player_icon = get_node("../Level/UI/Players/" + Client.user_id)
	player_icon.get_node("Ready").visible = true
	player_icon.get_node("NotReady").visible = false

func _on_not_ready_pressed():
	Client.set_ready(false)
	ready_button.visible = true
	not_ready_button.visible = false
	if not player_icon:
		player_icon = get_node("../Level/UI/Players/" + Client.user_id)
	player_icon.get_node("Ready").visible = false
	player_icon.get_node("NotReady").visible = true
