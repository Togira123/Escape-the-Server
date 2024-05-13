extends Node

class_name MultiplayerClient

signal on_authorize

const APP_ID = "1221502156880744499"
#const APP_ID = "1237787957872562247"
const DISCORDSAYS = APP_ID + ".discordsays.com"

const PLAYER = preload("res://scenes/player/player.tscn")

# make sure this is the same as on the server
enum ClientMessages {
	AUTHENTICATE,
	PING,
	USER_CHANGE,
	START_GAME,
	LOBBY,
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
	var is_ready: bool
	var running: bool
	var color: String
	func _init(_id, _username, _global_name, _is_ready, _running, _color):
		id = _id
		username = _username
		global_name = _global_name
		is_ready = _is_ready
		running = _running
		color = _color
	func toJSON():
		return {
			"id": id,
			"username": username,
			"global_name": global_name,
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
			s += "\n" + members[member].username
		return s

var _sent_initial_packet = false
var lobby: Lobby = null
var settings: Dictionary = {}

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
				print("Received Packet:")
				print(data)
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
					# start the game
					$"/root/Main".start_game()
				elif data["type"] == ServerMessages.DIED:
					$"/root/Main/Player".check_and_start_revive(data["stage"], data["user_id"])
				elif data["type"] == ServerMessages.REVIVED:
					if data["user_id"] == user_id:
						# this client has been revived
						$"/root/Main/Player".revive()
					else:
						var revive_node = get_node_or_null("/root/Main/Level/UI/Revive")
						if revive_node:
							revive_node.start_disappear_timer(data["by_user_id"])
	elif state == WebSocketPeer.STATE_CLOSED:
		print("Closed because of:")
		print(peer.get_close_code())
		# reconnect
		_sent_initial_packet = false
		print("RECONNECTING")
		peer.connect_to_url("wss://" + DISCORDSAYS + "/ws")
func request_lobby():
	var msg = {
		"type": ClientMessages.LOBBY,
	}
	peer.put_packet(JSON.stringify(msg).to_utf8_buffer())

func update_lobby(json):
	lobby.id = json.id
	lobby.leader_id = json.leader_id
	lobby.members = {}
	var other_players = get_tree().get_nodes_in_group("other_players")
	print(json.members)
	for member in json.members:
		var user = User.new(member.id, member.username, member.global_name, member.is_ready, member.running, member.color)
		lobby.members[user.id] = user
		if member.id == user_id:
			# do not add additional player node for the player that runs this game
			continue
		var exists = other_players.any(func(p): return p.user_id == member.id)
		# there's no player node for this lobby member, create one
		if not exists:
			var inst = PLAYER.instantiate()
			inst.user_id = member.id
			inst.add_to_group("other_players")
			inst.get_node("Armature/Skeleton3D/Skin").material_override.set_shader_parameter("half_transparent", lobby.members[inst.user_id].running)
			inst.get_node("Armature/Skeleton3D/Skin").material_override.set_shader_parameter("albedo", Color(lobby.members[inst.user_id].color))
			$"/root/Main".add_child(inst)
	for player in other_players:
		if not lobby.members.has(player.user_id):
			# there's a player node for someone that is not in the lobby, delete the player node
			player.queue_free()
		else:
			# update the player model
			player.get_node("Armature/Skeleton3D/Skin").material_override.set_shader_parameter("half_transparent", lobby.members[player.user_id].running)
			if player.user_id != user_id:
				# this user's player model is updated instantly in the code
				player.get_node("Armature/Skeleton3D/Skin").material_override.set_shader_parameter("albedo", Color(lobby.members[player.user_id].color))
	var main_menu = get_node_or_null("/root/Main/MainMenu")
	if main_menu:
		main_menu.update_play_button(false)

func leader_start_game():
	var msg = {
		"type": ClientMessages.START_GAME,
	}
	peer.put_packet(JSON.stringify(msg).to_utf8_buffer())

func set_ready(ready: bool):
	lobby.members[user_id].is_ready = ready
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
