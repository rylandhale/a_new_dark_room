extends Control

@onready var story_image = $VBoxContainer/TopLayer/StoryImage
@onready var story_log = $VBoxContainer/TopLayer/StoryLog
@onready var fire_timer = $VBoxContainer/FireTimer
@onready var inventory_ui = $VBoxContainer/BottomUI/Inventory
@onready var explore_ui = $VBoxContainer/BottomUI/ExploreUI

var axe_item = preload("res://assets/items/axe.tres")
var wood_item = preload("res://assets/items/wood.tres")

var story_state = 0  # 0 = intro, 1 = looked, 2 = picked up axe, 3 = woodcutting unlocked, 4 = spider encounter
var story_lines: Array = []
var spider_combat_scene = preload("res://combat/spider_combat.tscn")
var current_combat: Node2D

func log_story(text: String):
	for i in range(story_lines.size()):
		story_lines[i] = "[color=#888888]" + strip_bbcode(story_lines[i]) + "[/color]"
	story_lines.insert(0, "[color=#ffffff]" + strip_bbcode(text) + "[/color]")
	story_log.text = "\n\n".join(story_lines)

func strip_bbcode(line: String) -> String:
	var regex = RegEx.new()
	regex.compile("\\[color=.*?\\](.*?)\\[/color\\]")
	var match = regex.search(line)
	return match.get_string(1) if match else line

func _ready():
	log_story("You find yourself in a small dark room.\nA fire is lit, but it's slowly burning out.\nYou see a small pile of wood — some small enough to fit in the fire, others too large.")
	show_image("res://assets/backgrounds/dark_room.png")

	explore_ui.stoke_button.pressed.connect(_on_stoke_button_pressed)
	explore_ui.wood_button.pressed.connect(_on_wood_button_pressed)

	update_labels()
	update_inventory()

func _on_stoke_button_pressed():
	if GameState.remove_item("Wood"):
		GameState.change_resource("fire", 1)
		log_story("You add some wood to the fire. It burns brighter.")

		if story_state == 0:
			log_story("You add some wood to the fire. It burns brighter. By the light of the fire you are able to see you are in a room.")
			show_image("res://assets/backgrounds/lite_room.png")
			explore_ui.wood_button.text = "Look around the room"
			explore_ui.wood_button.show()
		else:
			log_story("The fire burns brighter.")

		update_labels()
		update_inventory()
	else:
		log_story("You have no wood.")

func _on_wood_button_pressed():
	match story_state:
		0:
			log_story("You see an old axe.")
			print("Axe icon: ", axe_item.icon) # Debug line
			show_image(axe_item.icon)
			explore_ui.wood_button.text = "Pick up the axe"
			story_state = 1

		1:
			log_story("You pick up the axe.")
			GameState.add_item(axe_item)
			show_image(wood_item.icon)
			explore_ui.wood_button.text = "Cut wood"
			story_state = 2
			update_inventory()

		2:
			log_story("You cut some larger logs into pieces you can use in the fire. Suddenly, you hear a skittering sound...")
			show_image("res://assets/backgrounds/lite_room.png")
			# Add 3 separate Wood items
			for i in range(3):
				GameState.add_item(wood_item.duplicate())
			update_inventory()
			update_labels()
			story_state = 3
			explore_ui.wood_button.text = "Look around"

		3:
			log_story("A spider emerges from the shadows!")
			show_image("res://assets/enemies/spider.png")
			explore_ui.wood_button.text = "Fight the spider"
			story_state = 4

		4:
			initiate_spider_combat()

		5, _:
			log_story("You gather more wood using the axe.")
			GameState.add_item(wood_item.duplicate())
			update_inventory()
			update_labels()

func _on_fire_timer_timeout():
	GameState.change_resource("fire", -1)

	if GameState.resources["fire"] <= 0 and GameState.resources["wood"] <= 0:
		explore_ui.stoke_button.disabled = true
		explore_ui.wood_button.disabled = true
		explore_ui.fire_label.text = "🔥 The fire has gone out."
		fire_timer.stop()
	else:
		update_labels()
		update_inventory()

func count_wood_in_inventory() -> int:
	var count = 0
	for item in GameState.inventory:
		if item is WoodItem:
			count += 1
	return count

func update_labels():
	explore_ui.update_labels(GameState.resources["fire"], count_wood_in_inventory())

func update_inventory():
	inventory_ui.update_inventory()

func show_image(image_source):
	var tex: Texture2D
	
	if image_source is String:
		tex = load(image_source)
	else:
		tex = image_source
		
	story_image.texture = tex
	story_image.modulate.a = 0.0
	var tween = get_tree().create_tween()
	tween.tween_property(story_image, "modulate:a", 1.0, 0.5)

func hide_image():
	var tween = get_tree().create_tween()
	tween.tween_property(story_image, "modulate:a", 0.0, 0.5)

func initiate_spider_combat():
	current_combat = spider_combat_scene.instantiate()
	add_child(current_combat)
	current_combat.combat_finished.connect(_on_combat_finished)
	explore_ui.wood_button.disabled = true

func _on_combat_finished(victory: bool):
	if victory:
		log_story("You've defeated the spider!")
		current_combat.queue_free()
		explore_ui.wood_button.disabled = false
		explore_ui.wood_button.text = "Cut wood from the pile"
		story_state = 5
		show_image("res://assets/backgrounds/lite_room.png")
