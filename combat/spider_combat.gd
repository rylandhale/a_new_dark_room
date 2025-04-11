extends Node2D

@onready var combat_log = $Control/VBoxContainer/CombatLog
@onready var spider_hp = $Control/VBoxContainer/SpiderHP
@onready var attack_button = $Control/VBoxContainer/AttackButton
@onready var spider: Entity = $Spider
var combat_manager: CombatManager

signal combat_finished(victory: bool)

func _ready():
	combat_manager = CombatManager.new()
	attack_button.pressed.connect(_on_attack_pressed)
	update_ui()

func _on_attack_pressed():
	# Create a temporary player entity for combat
	var player = Entity.new()
	player.entity_name = "Player"
	player.stats = {
		"health": 10,
		"attack": 5,
		"defense": 2
	}
	
	var result = combat_manager.fight(player, spider)
	combat_log.text = result
	update_ui()
	
	player.queue_free()
	
	if spider.stats.health <= 0:
		await get_tree().create_timer(2.0).timeout
		emit_signal("combat_finished", true)

func update_ui():
	spider_hp.text = "Spider HP: %d" % spider.stats.health 
