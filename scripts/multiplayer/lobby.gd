extends RefCounted

class_name Lobby

var host_id: int
var players = {}

func _init(id: int):
	host_id = id

func add_player(id: int, name: String):
	players[id] = {
		"name": name,
		"id": id,
		"index": players.size() + 1
	}
	return players[id]
