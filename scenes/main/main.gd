extends Control

@onready var story_container = $CenterContainer/VBoxContainer/TopLayer/StoryContainer
@onready var background_image = story_container.get_node("BackgroundImage")
@onready var story_log = $CenterContainer/VBoxContainer/TopLayer/StoryLog
@onready var fire_timer = $CenterContainer/VBoxContainer/FireTimer
@onready var inventory_ui = $CenterContainer/VBoxContainer/BottomUI/Inventory
@onready var explore_ui = $CenterContainer/VBoxContainer/BottomUI/ExploreUI

var axe_item = preload("res://assets/items/axe.tres")
var wood_item = preload("res://assets/items/wood.tres")

var story_state = 0  # 0 = intro, 1 = looked, 2 = picked up axe, 3 = woodcutting unlocked, 4 = spider encounter
var story_lines: Array = []
var spider_combat_scene = preload("res://combat/spider_combat.tscn")
var current_combat: Control

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
	set_background_image("res://assets/backgrounds/dark_room.png")

	explore_ui.stoke_button.pressed.connect(_on_stoke_button_pressed)
	explore_ui.wood_button.pressed.connect(_on_wood_button_pressed)

	update_labels()
	update_inventory()

func set_background_image(image_path: String) -> void:
	var tex = load(image_path)
	background_image.texture = tex

func show_image(image_source):
	var tex: Texture2D
	
	if image_source is String:
		tex = load(image_source)
	else:
		tex = image_source
		
	story_container.get_node("StoryImage").texture = tex
	story_container.get_node("StoryImage").modulate.a = 0.0
	var tween = get_tree().create_tween()
	tween.tween_property(story_container.get_node("StoryImage"), "modulate:a", 1.0, 0.5)

func load_scene_into_story_container(scene: PackedScene, on_finish: Callable):
	var instance = scene.instantiate()
	story_container.add_child(instance)
	instance.anchors_preset = Control.PRESET_FULL_RECT
	instance.offset_left = 0
	instance.offset_top = 0
	instance.offset_right = 0
	instance.offset_bottom = 0

	# Optional: Pass data to the scene
	if instance.has_signal("scene_finished"):
		instance.scene_finished.connect(on_finish)

	return instance

func _on_stoke_button_pressed():
	if GameState.remove_item("Wood"):
		GameState.change_resource("fire", 1)
		log_story("You add some wood to the fire. It burns brighter.")

		if story_state == 0:
			log_story("By the light of the fire you are able to see you are in a room.")
			set_background_image("res://assets/backgrounds/lite_room.png")
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
			set_background_image("res://assets/backgrounds/lite_room.png")
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

	if GameState.resources["fire"] <= 0 and GameState.count_item("Wood") <= 0:
		explore_ui.stoke_button.disabled = true
		explore_ui.wood_button.disabled = true
		explore_ui.fire_label.text = "🔥 The fire has gone out."
		fire_timer.stop()
	else:
		update_labels()
		update_inventory()

func update_labels():
	explore_ui.update_labels(GameState.resources["fire"], GameState.count_item("Wood"))

func update_inventory():
	inventory_ui.update_inventory()

func initiate_spider_combat():
	current_combat = load_scene_into_story_container(spider_combat_scene, _on_combat_finished)

	explore_ui.wood_button.text = "Attack!"
	explore_ui.wood_button.pressed.disconnect(_on_wood_button_pressed)
	explore_ui.wood_button.pressed.connect(_on_attack_pressed)

func _on_attack_pressed():
	if current_combat == null:
		return  # Already removed
	
	var result = current_combat.player_attack()
	log_story(result)

	# Check if spider is dead after attack
	if current_combat != null and current_combat.spider.stats.health <= 0:
		_on_combat_finished(true)

func _on_combat_finished(_victory: bool):
	# Disconnect attack button early
	if explore_ui.wood_button.pressed.is_connected(_on_attack_pressed):
		explore_ui.wood_button.pressed.disconnect(_on_attack_pressed)

	# Clean up combat scene and reset story container
	if current_combat != null:
		current_combat.queue_free()
		current_combat = null
		
	# Clear any remaining story images
	if story_container.has_node("StoryImage"):
		story_container.get_node("StoryImage").texture = null
		
	# Reset button to Explore
	explore_ui.wood_button.pressed.connect(_on_wood_button_pressed)
	explore_ui.wood_button.text = "Cut wood from the pile"
	explore_ui.wood_button.disabled = false

	log_story("You've defeated the spider!")

	# Back to normal scene
	story_state = 5
	set_background_image("res://assets/backgrounds/lite_room.png")
