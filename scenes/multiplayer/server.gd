extends Node

enum message {
	ID,
	JOIN,
	USER_CONNECTED,
	USER_DISCONNECTED,
	LOBBY,
	CANDIDATE,
	OFFER,
	ANSWER,
	CHECK_IN
}

const CHARACTERS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

var peer = WebSocketMultiplayerPeer.new()

const PORT = 2053

var users = {}

var lobbies = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	#if "--server" in OS.get_cmdline_args():
	print("Hosting on ", PORT)
	peer.create_server(PORT)
	peer.connect("peer_connected", peer_connected)
	peer.connect("peer_disconnected", peer_disconnected)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	peer.poll()
	if peer.get_available_packet_count() > 0:
		var packet = peer.get_packet()
		if packet != null:
			var data_string = packet.get_string_from_utf8()
			var data = JSON.parse_string(data_string)
			print(data)
			
			if data.message == message.LOBBY:
				join_lobby(data)
			elif data.message == message.OFFER || data.message == message.ANSWER || data.message == message.CANDIDATE:
				print("source id is ", data.orgPeer)
				send_to_player(data.peer, data)

func peer_connected(id):
	print("Peer connected: ", id)
	users[id] = {
		"message": message.ID,
		"id": id
	}
	send_to_player(id, users[id])
	

func peer_disconnected(id):
	pass

func join_lobby(user):
	var result = ""
	if user.lobby_id == "":
		user.lobby_id = generate_random_string()
		lobbies[user.lobby_id] = Lobby.new(user.id)
	var lobby = lobbies[user.lobby_id]
	var player = lobby.add_player(user.id, user.name)
	print(user.lobby_id)
	for p in lobby.players:
		
		var data = {
			"message": message.USER_CONNECTED,
			"id": user.id
		}
		send_to_player(str(p).to_int(), data)
		
		var data2 = {
			"message": message.USER_CONNECTED,
			"id": str(p).to_int()
		}
		send_to_player(user.id, data2)
		
		var lobby_info = {
			"message": message.LOBBY,
			"players": JSON.stringify(lobby.players),
			"host": lobby.host_id,
			"lobby": user.lobby_id
		}
		send_to_player(str(p).to_int(), lobby_info)
	
	var data = {
		"message": message.USER_CONNECTED,
		"id": user.id,
		"host": lobby.host_id,
		"player": lobby.players[str(user.id).to_int()],
		"lobby": user.lobby_id
	}
	send_to_player(user.id, data)

func send_to_player(user_id, data):
	peer.get_peer(user_id).put_packet(JSON.stringify(data).to_utf8_buffer())

func generate_random_string():
	var result = ""
	for i in range(32):
		var rand_ind = randi() % CHARACTERS.length()
		result += CHARACTERS[rand_ind]
	return result


func _on_button_2_button_down():
	var message = {
		"message": message.ID,
		"data": "test1"
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
