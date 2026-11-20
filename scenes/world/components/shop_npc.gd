class_name ShopNpc
extends Npc
## A merchant (PROJECT_PLAN.md §6.4, Phase 9): an Npc that, after its greeting dialogue, opens the
## shop menu (`shop_menu.tscn`) with its `stock`, and turns back once the player leaves it.
## Placeholder look: the Knight black recolour, like the other villagers (risk R5).

const SHOP_MENU: PackedScene = preload("res://scenes/ui/shop_menu.tscn")

## What it sells (bought at `ItemData.price`; anything sellable is bought back at half).
@export var stock: Array[ItemData] = []
## Shown at the top of the shop.
@export var shop_title: String = "Merchant"

## The shop menu, created on the first visit (null until then).
var shop_menu: ShopMenu


func interact(by: Node) -> void:
	if by is Node2D:
		face_towards((by as Node2D).global_position)
	interacted.emit(by)
	if not dialogue_id.is_empty():
		await DialogueManager.start(dialogue_id, portrait)
	if not is_inside_tree():
		return
	await open_shop()
	face(StringName(facing))


## Opens the shop and returns when the player leaves it.
func open_shop() -> void:
	if shop_menu == null:
		shop_menu = SHOP_MENU.instantiate() as ShopMenu
		add_child(shop_menu)
	shop_menu.open(stock, shop_title)
	await shop_menu.closed
