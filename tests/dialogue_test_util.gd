class_name DialogueTestUtil
extends RefCounted
## Test helper: closes any open dialogue, picking the first choice on choice lines.


static func close_dialogue() -> void:
	var guard: int = 0
	while DialogueManager.is_active and guard < 200:
		guard += 1
		if DialogueManager.runner != null and DialogueManager.runner.has_choices():
			DialogueManager.choose(0)
		else:
			DialogueManager.advance()
