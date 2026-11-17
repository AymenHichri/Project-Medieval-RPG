class_name RestPoint
extends Interactable
## A place to rest (PROJECT_PLAN.md Phase 7: "rest at the well"): fully heals the party (HP, MP,
## statuses), then shows its dialogue. Drop it on a prop like any Interactable.

signal rested


func interact(by: Node) -> void:
	GameState.heal_party()
	rested.emit()
	super.interact(by)
