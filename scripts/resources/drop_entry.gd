class_name DropEntry
extends Resource
## An item an enemy may drop, rolled once per defeated enemy.

@export var item: ItemData
@export_range(0.0, 1.0, 0.01) var chance: float = 0.1
