extends Node

class_name MultiplayerClient

#const APP_ID = "1221502156880744499"
const APP_ID = "1237787957872562247"
const DISCORDSAYS = APP_ID + ".discordsays.com"

@onready var label = $"/root/Main/Label"
@onready var discord: DiscordSDK = $"/root/Discord"

enum {
	REGISTER_USER
}

var peer: WebSocketPeer

# Called when the node enters the scene tree for the first time.
func init():
	# connect to server
	peer = WebSocketPeer.new()
	print(peer.connect_to_url("wss://" + DISCORDSAYS + "/ws"))
	label.text = "a"
	discord.connect("dispatch_any", _dispatch)
	# discord sdk
	discord.init(APP_ID)
	label.text = "waiting for ready"
	await discord.dispatch_ready
	label.text = "getting auth code"
	var auth = await discord.command_authorize("code", ["identify", "guilds"], "")
	label.text = "getting access token from server"
	var hreq = HTTPRequest.new()
	hreq.accept_gzip = false
	add_child(hreq)
	var token_res = hreq.request(
		"https://" + DISCORDSAYS + "/api/auth",
		["Content-Type: application/x-www-form-urlencoded"],
		HTTPClient.METHOD_POST,
		"code=" + auth["code"]
	)
	var response = await hreq.request_completed
	hreq.queue_free()
	var json = response[0].get_string_from_utf8()
	var token_json = JSON.parse_string(json)
	var token = token_json["access_token"]
	label.text = "sending auth"
	var authRes = await discord.command_authenticate(token)
	print("auth completed")
	discord.subscribe_to_events()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	peer.poll()
	print(peer.get_ready_state())

func register_discord_user(user_id: String):
	var message = {
		"type": REGISTER_USER,
		"discord_user_id": user_id
	}

func _dispatch(event, data):
	label.text += "\n[ DISPATCH ] ========================="
	label.text += "\nEVENT:" + event
	label.text += "\nDATA: " + str(data)
	label.text += "\n======================================"
