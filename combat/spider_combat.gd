extends Control

@onready var spider: Entity = $SpiderEntity
@onready var spider_hp = $SpiderHP
var combat_manager: CombatManager

signal scene_finished(victory: bool)

func _ready():
	combat_manager = CombatManager.new()
	# Set size to fill parent container
	custom_minimum_size = Vector2(400, 400)  # Match the size of your Spider TextureRect
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	
	# Ensure the spider texture is properly sized
	if has_node("Spider"):
		var spider_texture = $Spider as TextureRect
		spider_texture.custom_minimum_size = Vector2(400, 400)
		spider_texture.size_flags_horizontal = SIZE_SHRINK_CENTER
		spider_texture.size_flags_vertical = SIZE_SHRINK_CENTER
		
	update_ui()

func player_attack():
	var player = Entity.new()
	player.entity_name = "Player"
	player.stats = { "health": 10, "attack": 5, "defense": 2 }

	var result = combat_manager.fight(player, spider)
	
	queue_free_player(player)  # small helper for cleanup
	update_ui()
	
	if is_spider_dead():
		emit_signal("scene_finished", true)
		
	return result

func is_spider_dead() -> bool:
	return spider.stats.health <= 0

func queue_free_player(player):
	player.queue_free()

func update_ui():
	spider_hp.text = "Spider HP: %d" % spider.stats.health
