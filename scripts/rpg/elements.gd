class_name Elements
extends RefCounted
## Damage elements and affinity helpers. An affinity is a damage multiplier stored per element
## on an enemy (or, later, granted by equipment): 2.0 weak, 1.0 normal, 0.5 resist, 0.0 immune.

enum Element { PHYSICAL, FIRE, FROST, LIGHTNING, HOLY, SHADOW }

## Affinity of a target with no entry for an element.
const NORMAL: float = 1.0
## Multiplier at or above which a hit counts as a weakness ("WEAK!").
const WEAK: float = 2.0
## Multiplier for a resisted element.
const RESIST: float = 0.5
## Multiplier for an element the target is immune to.
const IMMUNE: float = 0.0


## Display name of an element, e.g. `"Fire"`.
static func name_of(element: Element) -> String:
	return (Element.keys()[element] as String).capitalize()


## The multiplier `affinities` gives `element` (NORMAL when absent).
static func affinity(affinities: Dictionary[Element, float], element: Element) -> float:
	return affinities.get(element, NORMAL)


static func is_weak(multiplier: float) -> bool:
	return multiplier > NORMAL


static func is_resisted(multiplier: float) -> bool:
	return multiplier < NORMAL and multiplier > IMMUNE


static func is_immune(multiplier: float) -> bool:
	return multiplier <= IMMUNE
