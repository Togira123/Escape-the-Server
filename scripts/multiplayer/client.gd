extends Node

class_name MultiplayerClient

signal on_authorize
signal lobby_updated

const APP_ID = "1221502156880744499"
#const APP_ID = "1237787957872562247"
const DISCORDSAYS = APP_ID + ".discordsays.com"
const DISCORDCDN = "https://cdn.discordapp.com"

const PLAYER = preload("res://scenes/player/player.tscn")
const PLAYER_ICON = preload("res://scenes/ui/player_icon.tscn")

# make sure this is the same as on the server
enum ClientMessages {
	AUTHENTICATE,
	PING,
	USER_CHANGE,
	START_GAME,
	END_GAME,
	DEAD,
	REVIVE
}
# make sure this is the same as on the server
enum ServerMessages {
	ERROR,
	PONG,
	USER,
	LOBBY_UPDATE,
	GAME_START,
	DIED,
	REVIVED
}

var peer: WebSocketPeer

var user_id: String

var is_authorized = false # used to only trigger the signal once
# if those two are true, the user is authorized
var _received_initial_lobby_data = false
var _received_initial_user_data = false

var connecting_to_server_percentage = 0.0

var ping_timer: SceneTreeTimer = null

var showed_loading_screen = false

class User:
	var id: String # discord user id
	var username: String
	var global_name: String
	var avatar_hash: String
	var is_ready: bool
	var running: bool
	var color: String
	func _init(_id, _username, _global_name, _avatar_hash, _is_ready, _running, _color):
		id = _id
		username = _username
		global_name = _global_name
		avatar_hash = _avatar_hash
		is_ready = _is_ready
		running = _running
		color = _color
	func toJSON():
		return {
			"id": id,
			"username": username,
			"global_name": global_name,
			"avatar_hash": avatar_hash,
			"is_ready": is_ready,
			"running": running,
			"color": color
		}


class Lobby:
	var id: String # lobby id, will be guild id + channel id
	var leader_id: String # discord user id of lobby leader
	var members: Dictionary
	func as_string() -> String:
		var s = "id: " + id
		s += "\nleader: " + leader_id
		s += "\nMembers:"
		for member in members:
			s += "\n" + str(members[member].toJSON())
		return s

var _sent_initial_packet = false
var lobby: Lobby = null
var settings: Dictionary = {}
# store user icons to not need to always fetch them from discord
var user_icons = {}

func _ready():
	set_process(false)

# Called inside of main
func init():
	lobby = Lobby.new()
	# discord sdk
	connecting_to_server_percentage = 0.1
	Discord.init(APP_ID)
	await Discord.dispatch_ready
	connecting_to_server_percentage = 0.2
	var auth = await Discord.command_authorize("code", ["identify"], "")
	connecting_to_server_percentage = 0.3
	var hreq = HTTPRequest.new()
	hreq.accept_gzip = false
	add_child(hreq)
	hreq.request(
		"https://" + DISCORDSAYS + "/api/auth?code=" + auth["code"],
		["Content-Type: application/x-www-form-urlencoded"],
		HTTPClient.METHOD_POST
	)
	var response = await hreq.request_completed
	connecting_to_server_percentage = 0.5
	hreq.queue_free()
	var json = response[3].get_string_from_utf8()
	var response_json = JSON.parse_string(json)
	var token = response_json["access_token"]
	user_id = response_json["user_id"]
	await Discord.command_authenticate(token)
	connecting_to_server_percentage = 0.7
	Discord.subscribe_to_events()
	# connect to websocket server
	peer = WebSocketPeer.new()
	peer.connect_to_url("wss://" + DISCORDSAYS + "/ws")
	connecting_to_server_percentage = 0.8
	ping_timer = get_tree().create_timer(5.0, true, false, true)
	set_process(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if not is_authorized and _received_initial_lobby_data and _received_initial_user_data:
		is_authorized = true
		connecting_to_server_percentage = 1.0
		on_authorize.emit()
			
	peer.poll()
	var state = peer.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		if not _sent_initial_packet:
			_sent_initial_packet = true
			var msg = {
				"type": ClientMessages.AUTHENTICATE,
				"user_id": user_id,
				"lobby_id": Discord.guild_id + Discord.instance_id
			}
			peer.put_packet(JSON.stringify(msg).to_utf8_buffer())
		else:
			if ping_timer.time_left == 0.0:
				var msg = {
					"type": ClientMessages.PING
				}
				peer.put_packet(JSON.stringify(msg).to_utf8_buffer())
				ping_timer = get_tree().create_timer(5.0)
		while peer.get_available_packet_count():
			var packet = peer.get_packet()
			if packet != null:
				var data_string = packet.get_string_from_utf8()
				var data = JSON.parse_string(data_string)
				if data["type"] == ServerMessages.ERROR:
					# handle error
					if data["message"] == "LOBBY_NOT_READY": # sent as response to START_GAME
						$"/root/Main/MainMenu".display_not_all_players_ready_message()
				elif data["type"] == ServerMessages.USER:
					if not _received_initial_user_data:
						_received_initial_user_data = true
						connecting_to_server_percentage += 0.1
					# load settings
					settings = data["settings"]
				elif data["type"] == ServerMessages.LOBBY_UPDATE:
					update_lobby(data["lobby"])
					if not _received_initial_lobby_data:
						_received_initial_lobby_data = true
						connecting_to_server_percentage += 0.1
				elif data["type"] == ServerMessages.GAME_START:
					# set everyone's states correctly as on the server
					for member in lobby.members:
						lobby.members[member].is_ready = false
						lobby.members[member].running = true
					# start the game
					$"/root/Main".start_game()
				elif data["type"] == ServerMessages.DIED:
					var died_user_id = data["user_id"]
					$"/root/Main/Player".check_and_start_revive(data["stage"], died_user_id)
					if lobby.members[user_id].running:
						# if this user is running show a skull for the player that died
						get_node("/root/Main/Level/UI/Players/" + died_user_id + "/Dead").visible = true
				elif data["type"] == ServerMessages.REVIVED:
					if data["user_id"] == user_id:
						# this client has been revived
						$"/root/Main/Player".revive()
					else:
						var revive_node = get_node_or_null("/root/Main/Level/UI/Revive")
						if revive_node:
							revive_node.start_disappear_timer(data["by_user_id"])
					if lobby.members[user_id].running:
						# if this user is running remove the skull for the player that died
						get_node("/root/Main/Level/UI/Players/" + data["user_id"] + "/Dead").visible = false
	elif state == WebSocketPeer.STATE_CLOSED:
		print("Connection Closed: :", peer.get_close_code())
		# reconnect
		_sent_initial_packet = false
		print("RECONNECTING")
		peer.connect_to_url("wss://" + DISCORDSAYS + "/ws")

func update_lobby(json):
	print(json.members)
	lobby.id = json.id
	lobby.leader_id = json.leader_id
	lobby.members = {}
	var other_players = get_tree().get_nodes_in_group("other_players")
	for member in json.members:
		# first make sure to save all users in lobby
		var user = User.new(member.id, member.username, member.global_name, member.avatar_hash, member.is_ready, member.running, member.color)
		lobby.members[user.id] = user
	# then iterate and update stuff accordingly
	for member in json.members:
		if member.id == user_id:
			# still add player icon for ui
			if not has_node("/root/Main/Level/UI/Players/" + user_id):
				var player_icon = PLAYER_ICON.instantiate()
				player_icon.name = user_id
				$"/root/Main/Level/UI/Players".add_child(player_icon)
				if member.avatar_hash != null:
					fetch_avatar(member.id, member.avatar_hash)
			if not member.running and lobby.leader_id == user_id:
				get_node("/root/Main/Level/UI/Players/" + user_id + "/Ready").visible = false
				get_node("/root/Main/Level/UI/Players/" + user_id + "/NotReady").visible = false
				get_node("/root/Main/Level/UI/Players/" + user_id + "/Leader").visible = true
			# do not add additional player node for the player that runs this game
			continue
		var exists = other_players.any(func(p): return p.user_id == member.id)
		# there's no player node for this lobby member, create one
		if not exists:
			var inst = PLAYER.instantiate()
			inst.user_id = member.id
			inst.add_to_group("other_players")
			var is_running = lobby.members[inst.user_id].running
			inst.get_node("Armature/Skeleton3D/Skin").material_override.set_shader_parameter("half_transparent", is_running)
			inst.get_node("Armature/Skeleton3D/Skin").material_override.set_shader_parameter("albedo", Color(lobby.members[inst.user_id].color))
			var player_icon = PLAYER_ICON.instantiate()
			player_icon.name = member.id
			$"/root/Main/Level/UI/Players".add_child(player_icon)
			if member.avatar_hash != null:
				fetch_avatar(member.id, member.avatar_hash)
			if lobby.members[user_id].running:
				# new player joined while this user is running, show the lobby icon
				get_node("/root/Main/Level/UI/Players/" + inst.user_id + "/Lobby").visible = not is_running
				# don't show the not ready button which is enabled by default
				get_node("/root/Main/Level/UI/Players/" + inst.user_id + "/NotReady").visible = false
			else:
				# if this user is not running (-> he's in the lobby), display other users that are running as running
				get_node("/root/Main/Level/UI/Players/" + inst.user_id + "/Running").visible = is_running
				# also update whether this user is ready or not
				var ready_icon = get_node("/root/Main/Level/UI/Players/" + inst.user_id + "/Ready")
				var not_ready_icon = get_node("/root/Main/Level/UI/Players/" + inst.user_id + "/NotReady")
				if lobby.leader_id == member.id:
					ready_icon.visible = false
					not_ready_icon.visible = false
					get_node("/root/Main/Level/UI/Players/" + inst.user_id + "/Leader").visible = true
				elif member.is_ready:
					ready_icon.visible = true
					not_ready_icon.visible = false
				else:
					ready_icon.visible = false
					not_ready_icon.visible = true
			$"/root/Main".add_child(inst)
	for player in other_players:
		if not lobby.members.has(player.user_id):
			# there's a player node for someone that is not in the lobby, delete the player node
			player.queue_free()
			get_node("/root/Main/Level/UI/Players/" + player.user_id).queue_free()
		else:
			# update the player model
			var member = lobby.members[player.user_id]
			var is_running = member.running
			player.get_node("Armature/Skeleton3D/Skin").material_override.set_shader_parameter("half_transparent", is_running)
			if not lobby.members[user_id].running:
				# if this user is not running (-> he's in the lobby), display other users that are running as running
				get_node("/root/Main/Level/UI/Players/" + player.user_id + "/Running").visible = is_running
				# also update whether this user is ready or not
				var ready_icon = get_node("/root/Main/Level/UI/Players/" + player.user_id + "/Ready")
				var not_ready_icon = get_node("/root/Main/Level/UI/Players/" + player.user_id + "/NotReady")
				if lobby.leader_id == player.user_id:
					ready_icon.visible = false
					not_ready_icon.visible = false
					get_node("/root/Main/Level/UI/Players/" + player.user_id + "/Leader").visible = true
				elif member.is_ready:
					ready_icon.visible = true
					not_ready_icon.visible = false
				else:
					ready_icon.visible = false
					not_ready_icon.visible = true
			
			player.get_node("Armature/Skeleton3D/Skin").material_override.set_shader_parameter("albedo", Color(member.color))
	var main_menu = get_node_or_null("/root/Main/MainMenu")
	if main_menu:
		main_menu.update_play_button(false)
	lobby_updated.emit()

func fetch_avatar(user_id: String, avatar_hash: String):
	if user_icons.has(user_id):
		# user icon is cached already, do not make request
		var icon = get_node("/root/Main/Level/UI/Players/" + user_id + "/Icon")
		var correct_size = icon.texture.get_size()
		icon.texture = user_icons[user_id]
		icon.scale = icon.scale * (correct_size / icon.texture.get_size())
		return
	var http_req = HTTPRequest.new()
	add_child(http_req)
	http_req.request_completed.connect(_set_avatar.bind(user_id))
	http_req.request(DISCORDCDN + "/avatars/%s/%s.png?size=256" % [user_id, avatar_hash])

func _set_avatar(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, user_id: String):
	if result != HTTPRequest.RESULT_SUCCESS:
		# error, keep default image
		return
	var image = Image.new()
	var error = image.load_png_from_buffer(body)
	if error != OK:
		# error, keep default image
		return
	var icon = get_node("/root/Main/Level/UI/Players/" + user_id + "/Icon")
	var correct_size = icon.texture.get_size()
	icon.texture = ImageTexture.create_from_image(image)
	user_icons[user_id] = icon.texture
	icon.scale = icon.scale * (correct_size / icon.texture.get_size())

func leader_start_game():
	var msg = {
		"type": ClientMessages.START_GAME,
	}
	peer.put_packet(JSON.stringify(msg).to_utf8_buffer())

func set_ready(ready: bool):
	lobby.members[user_id].is_ready = ready
	print("updated ready cause set_ready")
	update_user()

func send_death(stage: int):
	var msg = {
		"type": ClientMessages.DEAD,
		"stage": stage
	}
	peer.put_packet(JSON.stringify(msg).to_utf8_buffer())

func send_revive(target_user_id: String):
	var msg = {
		"type": ClientMessages.REVIVE,
		"target_user_id": target_user_id
	}
	peer.put_packet(JSON.stringify(msg).to_utf8_buffer())

# used to update settings or user state
func update_user():
	var msg = {
		"type": ClientMessages.USER_CHANGE,
		"user": lobby.members[user_id].toJSON(),
		"settings": settings
	}
	peer.put_packet(JSON.stringify(msg).to_utf8_buffer())

func return_to_menu():
	var msg = {
		"type": ClientMessages.END_GAME,
	}
	peer.put_packet(JSON.stringify(msg).to_utf8_buffer())
