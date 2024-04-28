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

var peer = WebSocketMultiplayerPeer.new()
var rtc_peer = WebRTCMultiplayerPeer.new()
var id = 0
var host_id = 0
var lobby = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer.connected_to_server.connect(rtc_server_connected)
	multiplayer.peer_connected.connect(rtc_peer_connected)
	multiplayer.peer_disconnected.connect(rtc_peer_disconnected)
	# connect to server
	connect_to_server("")

func rtc_server_connected():
	print("rtc server connected")

func rtc_peer_connected(id):
	print("rtc peer connected ", id)

func rtc_peer_disconnected(id):
	print("rtc peer disconnected ", id)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	peer.poll()
	if peer.get_available_packet_count() > 0:
		var packet = peer.get_packet()
		if packet != null:
			var data_string = packet.get_string_from_utf8()
			var data = JSON.parse_string(data_string)
			print(data)
			if data.message == message.ID:
				id = data.id
				connected(id)
				#create lobby
				var msg = {
					"id": id,
					"message": message.LOBBY,
					"name": "User123",
					"lobby_id": $LineEdit.text
				}
				peer.put_packet(JSON.stringify(msg).to_utf8_buffer())
			elif data.message == message.USER_CONNECTED:
					#GameManager.players[data.id] = data.player
				create_peer(data.id)
			elif data.message == message.LOBBY:
				GameManager.players = JSON.parse_string(data.players)
				host_id = data.host
				lobby = data.lobby
			elif data.message == message.CANDIDATE:
				if rtc_peer.has_peer(data.orgPeer):
					print("got candidate: ", data.orgPeer, " my id is ", id)
					rtc_peer.get_peer(data.orgPeer).connection.add_ice_candidate(data.mid, data.index, data.sdp)
			elif data.message == message.OFFER:
				if rtc_peer.has_peer(data.orgPeer):
					rtc_peer.get_peer(data.orgPeer).connection.set_remote_description("offer", data.data)
			elif data.message == message.ANSWER:
				if rtc_peer.has_peer(data.orgPeer):
					rtc_peer.get_peer(data.orgPeer).connection.set_remote_description("answer", data.data)


func connected(id):
	rtc_peer.create_mesh(id)
	multiplayer.multiplayer_peer = rtc_peer

func create_peer(id: int):
	if id != self.id:
		var peer = WebRTCPeerConnection.new()
		peer.initialize({
			"iceServers": [{ "urls": ["stun:stun.l.google.com:19302", "stun:stun1.l.google.com:19302", "stun:stun2.l.google.com:19302", "stun:stun3.l.google.com:19302", "stun:stun4.l.google.com:19302"]}]
		})
		print("binding id ", id, " my id is ", self.id)
		
		peer.session_description_created.connect(offer_created.bind(id))
		peer.ice_candidate_created.connect(ice_candidate_created.bind(id))
		rtc_peer.add_peer(peer, id)
		
		if id < rtc_peer.get_unique_id():
			peer.create_offer()

func offer_created(type, data, id: int):
	if not rtc_peer.has_peer(id):
		return
		
	rtc_peer.get_peer(id).connection.set_local_description(type, data)
	
	if type == "offer":
		send_offer(id, data)
	else:
		send_answer(id, data)

func send_offer(id: int, data):
	var msg = {
		"peer": id,
		"orgPeer": self.id,
		"message": message.OFFER,
		"data": data,
		"lobby": lobby
	}
	peer.put_packet(JSON.stringify(msg).to_utf8_buffer())

func send_answer(id: int, data):
	var msg = {
		"peer": id,
		"orgPeer": self.id,
		"message": message.ANSWER,
		"data": data,
		"lobby": lobby
	}
	peer.put_packet(JSON.stringify(msg).to_utf8_buffer())


func ice_candidate_created(mid_name, index_name, sdp_name, id: int):
	var msg = {
		"peer": id,
		"orgPeer": self.id,
		"message": message.CANDIDATE,
		"mid": mid_name,
		"index": index_name,
		"sdp": sdp_name,
		"lobby": lobby
	}
	peer.put_packet(JSON.stringify(msg).to_utf8_buffer())

func connect_to_server(ip: String):
	peer.create_client("ws://1221502156880744499.discordsays.com:2053")
	print("started_client")

func _on_start_client_button_down():
	connect_to_server("")
	pass # Replace with function body.


func _on_button_button_down():
	ping.rpc()

@rpc("any_peer")
func ping():
	print("ping from ", multiplayer.get_remote_sender_id())

func _on_join_lobby_button_down():
	var msg = {
		"id": id,
		"message": message.LOBBY,
		"name": "User123",
		"lobby_id": $LineEdit.text
	}
	peer.put_packet(JSON.stringify(msg).to_utf8_buffer())
