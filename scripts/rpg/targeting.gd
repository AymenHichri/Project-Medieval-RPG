class_name Targeting
extends RefCounted
## Who a skill or item can be used on, seen from the user's side.

enum Mode { ONE_ENEMY, ALL_ENEMIES, ONE_ALLY, ALL_ALLIES, SELF }


static func is_single(mode: Mode) -> bool:
	return mode == Mode.ONE_ENEMY or mode == Mode.ONE_ALLY or mode == Mode.SELF


static func targets_opponents(mode: Mode) -> bool:
	return mode == Mode.ONE_ENEMY or mode == Mode.ALL_ENEMIES
