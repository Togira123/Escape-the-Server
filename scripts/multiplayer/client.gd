extends Node

class_name MultiplayerClient

#const APP_ID = "1221502156880744499"
const APP_ID = "1237787957872562247"
const DISCORDSAYS = APP_ID + ".discordsays.com"

@onready var label = $"/root/Main/Label"

enum {
	REGISTER_USER
}

var peer: WebSocketPeer

var user_id: String

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
var lobby

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
		"https://" + DISCORDSAYS + "/api/auth?code=" + auth["code"] + "&lobby_id=" + Discord.guild_id + Discord.channel_id,
		["Content-Type: application/x-www-form-urlencoded"],
		HTTPClient.METHOD_POST
	)
	var response = await hreq.request_completed
	hreq.queue_free()
	var json = response[3].get_string_from_utf8()
	var response_json = JSON.parse_string(json)
	var token = response_json["access_token"]
	var lobby_json = response_json["lobby"]
	update_lobby(lobby_json)
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
				text = "hello"
			}
			peer.put_packet(JSON.stringify(msg).to_utf8_buffer())
			

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
	for member in json.members:
		var user = User.new(member.id, member.username, member.global_name)
		lobby.members[user.id] = user
		
	
