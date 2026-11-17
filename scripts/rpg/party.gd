class_name Party
extends RefCounted
## The active party (PROJECT_PLAN.md §6.4): up to MAX_ACTIVE members, in battle order.
## Phase 7 has one member (the Knight); recruiting arrives in Phase 8.

const MAX_ACTIVE: int = 3

var members: Array[PartyMember] = []


## Adds a member. Returns false (and adds nothing) when the party is full.
func add(member: PartyMember) -> bool:
	if member == null or members.size() >= MAX_ACTIVE or member in members:
		return false
	members.append(member)
	return true


func clear() -> void:
	members.clear()


func is_empty() -> bool:
	return members.is_empty()


func size() -> int:
	return members.size()


func leader() -> PartyMember:
	return members[0] if not members.is_empty() else null


## The fighters taken into a battle, in party order.
func combatants() -> Array[Combatant]:
	var out: Array[Combatant] = []
	for member: PartyMember in members:
		out.append(member.combatant)
	return out


## The member whose fighter is `c` (null if none).
func member_of(c: Combatant) -> PartyMember:
	for member: PartyMember in members:
		if member.combatant == c:
			return member
	return null


func heal_all() -> void:
	for member: PartyMember in members:
		member.heal_full()


## Clears what only lasts one battle (Defend, statuses).
func settle_after_battle() -> void:
	for member: PartyMember in members:
		member.combatant.is_defending = false
		member.combatant.statuses.clear()
