extends Node

#const APP_ID = "1221502156880744499"
const APP_ID = "1237787957872562247"
const DISCORDSAYS = "https://" + APP_ID + ".discordsays.com"

enum {
	REGISTER_USER
}

var peer: WebSocketPeer

# Called when the node enters the scene tree for the first time.
func _ready():
	# connect to server
	peer = WebSocketPeer.new()
	print(peer.connect_to_url("wss://1237787957872562247.discordsays.com/ws"))
	# discord sdk
	Discord.init(APP_ID)
	print("waiting for ready")
	await Discord.dispatch_ready
	print("getting auth code")
	var auth = await Discord.command_authorize("code", ["identify", "guilds"], "")
	print("getting access token from server")
	var hreq = HTTPRequest.new()
	hreq.accept_gzip = false
	add_child(hreq)
	var token_res = hreq.request(
		DISCORDSAYS + "/api/auth",
		["Content-Type: application/x-www-form-urlencoded"],
		HTTPClient.METHOD_POST,
		"code=" + auth["code"]
	)
	var response = await hreq.request_completed
	hreq.queue_free()
	var json = response[0].get_string_from_utf8()
	var token_json = JSON.parse_string(json)
	var token = token_json["access_token"]
	print("sending auth")
	var authRes = await Discord.command_authenticate(token)
	print("auth completed")
	Discord.subscribe_to_events()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	peer.poll()
	print(peer.get_ready_state())

func register_discord_user(user_id: String):
	var message = {
		"type": REGISTER_USER,
		"discord_user_id": user_id
	}
