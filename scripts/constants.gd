extends Node

var sentences

func get_random_sentence():
	if not sentences:
		var file = FileAccess.open("res://assets/text/sentences-list.txt", FileAccess.READ)
		var text = file.get_as_text()
		sentences = text.split("\n")
	return sentences[randi() % sentences.size()]
