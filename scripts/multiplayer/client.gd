extends Node

class_name MultiplayerClient

signal on_authorize

#const APP_ID = "1221502156880744499"
const APP_ID = "1237787957872562247"
const DISCORDSAYS = APP_ID + ".discordsays.com"

const PLAYER = preload("res://scenes/player/player.tscn")

@onready var label = $"/root/Main/Label"
@onready var main = $"/root/Main"

# make sure this is the same as on the server
enum ClientMessages {
	AUTHENTICATE
}
# make sure this is the same as on the server
enum ServerMessages {
	ERROR,
	LOBBY_UPDATE
}

var peer: WebSocketPeer

var user_id: String

var is_authorized = false # used to only trigger the signal once

class User:
	var id: String # discord user id
	var username: String
	var global_name: String
	func _init(id, username, global_name):
		self.id = id
		self.username = username
		self.global_name = global_name


class Lobby:
	var id: String # lobby id, will be guild id + channel id
	var leader_id: String # discord user id of lobby leader
	var members: Dictionary
	func as_string() -> String:
		var str = "id: " + id
		str += "\nleader: " + leader_id
		str += "\nMembers:"
		for member in members:
			str += "\n" + members[member].username
		print("final: ", str)
		return str

var initialized = false
var _sent_initial_packet = false
var lobby: Lobby = null

func _ready():
	set_process(false)

# Called inside of main
func init():
	print("INITIALIZED")
	lobby = Lobby.new()
	initialized = true
	Discord.connect("dispatch_current_user_update", _dispatch_current_user_update)
	Discord.connect("dispatch_activity_instance_participants_update", _dispatch_activity_instance_participants_update)
	# discord sdk
	Discord.init(APP_ID)
	label.text = "waiting for ready"
	await Discord.dispatch_ready
	label.text = "getting auth code"
	var auth = await Discord.command_authorize("code", ["identify"], "")
	label.text = "getting access token from server"
	var hreq = HTTPRequest.new()
	hreq.accept_gzip = false
	add_child(hreq)
	var token_res = hreq.request(
		"https://" + DISCORDSAYS + "/api/auth?code=" + auth["code"] + "&lobby_id=" + Discord.guild_id + Discord.instance_id,
		["Content-Type: application/x-www-form-urlencoded"],
		HTTPClient.METHOD_POST
	)
	var response = await hreq.request_completed
	hreq.queue_free()
	var json = response[3].get_string_from_utf8()
	var response_json = JSON.parse_string(json)
	var token = response_json["access_token"]
	user_id = response_json["user_id"]
	label.text = token
	label.text += "Lobby:\n"
	label.text += lobby.as_string()
	var authRes = await Discord.command_authenticate(token)
	print("auth completed")
	Discord.subscribe_to_events()
	# connect to websocket server
	peer = WebSocketPeer.new()
	peer.connect_to_url("wss://" + DISCORDSAYS + "/ws")
	set_process(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
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
		
		while peer.get_available_packet_count():
			var packet = peer.get_packet()
			if packet != null:
				var data_string = packet.get_string_from_utf8()
				var data = JSON.parse_string(data_string)
				if data["type"] == ServerMessages.LOBBY_UPDATE:
					update_lobby(data["lobby"])
					label.text += "Lobby:\n"
					label.text += lobby.as_string()
					if not is_authorized:
						is_authorized = true
						on_authorize.emit()
			

func _dispatch_current_user_update(data):
	var user_data = JSON.stringify(data)
	label.text += "\n" + user_data

func _dispatch_activity_instance_participants_update(data):
	var user_data = JSON.stringify(data)
	label.text += "\n" + user_data

func update_lobby(json):
	lobby.id = json.id
	lobby.leader_id = json.leader_id
	lobby.members = {}
	var other_players = get_tree().get_nodes_in_group("other_players")
	
	for member in json.members:
		var user = User.new(member.id, member.username, member.global_name)
		lobby.members[user.id] = user
		if member.id == user_id:
			# do not add additional player node for the player that runs this game
			continue
		var exists = other_players.any(func(p): p.user_id == member.id)
		# there's no player node for this lobby member, create one
		if not exists:
			var inst = PLAYER.instantiate()
			inst.user_id = member.id
			inst.add_to_group("other_players")
			main.add_child(inst)
	for player in other_players:
		if not lobby.members.has(player.user_id):
			# there's a player node for someone that is not in the lobby, delete the player node
			player.queue_free()
	
	
