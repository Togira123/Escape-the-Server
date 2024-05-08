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

var initialized = false

func _ready():
	set_process(false)

# Called inside of main
func init():
	print("INITIALIZED")
	initialized = true
	set_process(true)
	# connect to server
	peer = WebSocketPeer.new()
	print(peer.connect_to_url("wss://" + DISCORDSAYS + "/ws"))
	label.text = "a"
	Discord.connect("dispatch_any", _dispatch)
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
		"https://" + DISCORDSAYS + "/api/auth?code=" + auth["code"],
		["Content-Type: application/x-www-form-urlencoded"],
		HTTPClient.METHOD_POST
	)
	var response = await hreq.request_completed
	hreq.queue_free()
	var json = response[3].get_string_from_utf8()
	var token_json = JSON.parse_string(json)
	var token = token_json["access_token"]
	label.text = token
	var authRes = await Discord.command_authenticate(token)
	print("auth completed")
	Discord.subscribe_to_events()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	peer.poll()

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
