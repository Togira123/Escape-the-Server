extends Control

signal game_start

@onready var player = $"../Player"
@onready var leaderboard = $Leaderboard
@onready var settings = $Settings
@onready var shop = $Shop
@onready var help = $Help

func _on_game_start_button_pressed():
	game_start.emit()
	# remove main menu from scene tree
	queue_free()

func _on_leaderboard_button_pressed():
	settings.visible = false
	shop.visible = false
	leaderboard.visible = true
	await get_tree().create_timer(3.0).timeout
	leaderboard.visible = false

func _on_settings_button_pressed():
	leaderboard.visible = false
	shop.visible = false
	settings.visible = true
	await get_tree().create_timer(3.0).timeout
	settings.visible = false

func _on_shop_button_pressed():
	settings.visible = false
	leaderboard.visible = false
	shop.visible = true
	await get_tree().create_timer(3.0).timeout
	shop.visible = false

func _on_help_button_pressed():
	help.visible = true
	help.get_node("TabBar").call_deferred("grab_focus")
	$TransparentBg.visible = true

func _on_transparent_bg_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		$Help.close()
