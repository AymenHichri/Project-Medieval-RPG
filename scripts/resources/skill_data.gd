class_name SkillData
extends Resource
## A battle technique (SKILL, physical) or spell (MAGIC).
## Physical: `power` is a percentage of a basic attack (100 = one normal hit).
## Magic damage and healing: `power` is the spell's flat base (see DamageCalculator).
## Support effects (Phase 8): STATUS applies `inflicts` (Blessing, Provoke), CURE removes `cures`
## (Purify), GUARD makes the user defend and take the single-target blows aimed at its target.

enum Category { SKILL, MAGIC }
enum Effect { DAMAGE, HEAL, STATUS, CURE, GUARD }

@export var id: StringName
@export var display_name: String = ""
@export var category: Category = Category.SKILL
@export var effect: Effect = Effect.DAMAGE
@export_range(0, 999) var mp_cost: int = 0
@export_range(0, 9999) var power: int = 100
## Attacker stat the formula reads: `attack` for SKILL, `magic` for MAGIC by default.
@export var scaling_stat: StringName = &"attack"
@export var element: Elements.Element = Elements.Element.PHYSICAL
@export var target_mode: Targeting.Mode = Targeting.Mode.ONE_ENEMY
## Number of hits on each target.
@export_range(1, 9) var hits: int = 1
## Status inflicted on each damaged target with probability `inflict_chance`.
@export var inflicts: StatusEffectData
@export_range(0.0, 1.0, 0.01) var inflict_chance: float = 0.0
## Statuses removed from each target by a CURE skill (empty = all).
@export var cures: Array[StatusEffectData] = []
## Status the user puts on itself after the skill (Phase 10: the boss's big attacks leave it
## Staggered, an opening for the party). Null = none.
@export var user_inflicts: StatusEffectData
## Effect played on the user as the skill starts (the boss's phase trail). Null = none.
@export var user_fx: FxSpec
## Acts before ordinary actions of the round, like Defend (Guard: 1).
@export_range(0, 1) var priority: int = 0
## Logical animation the presenter plays (Phase 5), e.g. &"whirlwind".
@export var anim_key: StringName = &"attack"
## Effect the presenter plays on each target as the skill lands (null = the target's own hit
## effect for physical damage, nothing otherwise).
@export var impact_fx: FxSpec
## Played as it is used (on the cast animation for spells).
@export var cast_sfx: SfxSet
## Played on each target as it lands, with `impact_fx` (null = the default hit sound).
@export var impact_sfx: SfxSet
@export_multiline var description: String = ""


## Damages its targets (the only kind enemies pick at random, see EnemyAI).
func is_offensive() -> bool:
	return effect == Effect.DAMAGE
