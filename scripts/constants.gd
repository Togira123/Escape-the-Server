extends Node

var sentences

var next_sentence_position_z = 200

var ground_pattern_color_change_progress: float = 0

func get_random_sentence():
	if not sentences:
		var file = FileAccess.open("res://assets/text/sentences-list.txt", FileAccess.READ)
		var text = file.get_as_text()
		sentences = text.split("\n")
	return sentences[randi() % sentences.size()]
