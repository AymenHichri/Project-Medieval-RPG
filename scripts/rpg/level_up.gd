class_name LevelUp
extends RefCounted
## One level gained by a party member (returned by `PartyMember.gain_xp`).

var member_name: String = ""
## The level reached.
var level: int = 1
## Stats added by this level.
var gains: StatBlock
## Skills learned on reaching this level.
var learned: Array[SkillData] = []


## "Knight reached level 3!" (+ one line per learned skill).
func describe() -> PackedStringArray:
	var lines: PackedStringArray = ["%s reached level %d!" % [member_name, level]]
	for skill: SkillData in learned:
		lines.append("%s learned %s!" % [member_name, skill.display_name])
	return lines
