extends Control

@onready var story_image = $VBoxContainer/StoryImage
@onready var story_log = $VBoxContainer/HBoxContainer/StoryLog
@onready var fire_label = $VBoxContainer/HBoxContainer/VBoxContainer/FireLabel
@onready var wood_label = $VBoxContainer/HBoxContainer/VBoxContainer/WoodLabel
@onready var stoke_button = $VBoxContainer/HBoxContainer/VBoxContainer/StokeButton
@onready var wood_button = $VBoxContainer/HBoxContainer/VBoxContainer/WoodButton
@onready var fire_timer = $VBoxContainer/FireTimer

var picked_up_axe = false
var story_state = 0  # 0 = intro, 1 = looked, 2 = picked up axe, 3 = woodcutting unlocked
var cut_wood_enabled = false
var story_lines: Array = []

func log_story(text: String):
	# First, remove BBCode color tags from all lines
	for i in range(story_lines.size()):
		story_lines[i] = "[color=#888888]" + strip_bbcode(story_lines[i]) + "[/color]"

	# Insert new line on top as bright
	story_lines.insert(0, "[color=#ffffff]" + strip_bbcode(text) + "[/color]")

	story_log.text = "\n\n".join(story_lines)

func strip_bbcode(line: String) -> String:
	var regex = RegEx.new()
	regex.compile("\\[color=.*?\\](.*?)\\[/color\\]")
	var match = regex.search(line)
	return match.get_string(1) if match else line

func _ready():
	# Don't hardcode story_log.text here — use log_story() so it applies formatting
	log_story("You find yourself in a small dark room.\nA fire is lit, but it’s slowly burning out.\nYou see a small pile of wood — some small enough to fit in the fire, others too large.")
	show_image("res://assets/dark_room.png")
	stoke_button.text = "Stoke the Fire"
	stoke_button.pressed.connect(_on_stoke_button_pressed)

	wood_button.hide()
	update_labels()

func _on_stoke_button_pressed():
	if GameState.resources["wood"] > 0:
		GameState.change_resource("fire", 1)
		GameState.change_resource("wood", -1)

		if story_state == 0:
			log_story("You add some wood to the fire. It burns brighter. By the light of the fire you are able to see you are in a room.")
			show_image("res://assets/fireplace.png")  # <- here
			wood_button.text = "Look around the room"
			if not wood_button.pressed.is_connected(_on_wood_button_pressed):
				wood_button.pressed.connect(_on_wood_button_pressed)
			wood_button.show()
		else:
			log_story("The fire burns brighter.")
		
		update_labels()

func _on_wood_button_pressed():
	match story_state:
		0:
			log_story("You see a mostly empty room — the fire, the wood pile. In the corner, you see an old axe.")
			show_image("res://assets/axe.png")
			wood_button.text = "Pick up the axe"
			story_state = 1

		1:
			log_story("You pick up the axe. You can now cut larger wood into logs.")
			show_image("res://assets/wood.png")
			picked_up_axe = true
			wood_button.text = "Cut wood from the pile"
			story_state = 2

		2:
			log_story("You cut some larger logs into pieces you can use in the fire.")
			show_image("res://assets/fireplace.png")
			GameState.change_resource("wood", 3)
			update_labels()
			story_state = 3  # optional: now you're in freeform woodcutting mode

		_:
			# Optional: log if clicked again in the future
			log_story("You gather more wood using the axe.")
			GameState.change_resource("wood", 2)
			update_labels()

func _on_fire_timer_timeout():
	GameState.change_resource("fire", -1)

	if GameState.resources["fire"] <= 0 and GameState.resources["wood"] <= 0:
		stoke_button.disabled = true
		wood_button.disabled = true
		fire_label.text = "🔥 The fire has gone out."
		fire_timer.stop()
	else:
		update_labels()

func update_labels():
	fire_label.text = "🔥 Fire level: %d" % GameState.resources["fire"]
	wood_label.text = "🪵 Wood: %d" % GameState.resources["wood"]

	stoke_button.disabled = GameState.resources["wood"] <= 0

func show_image(path: String):
	var tex = load(path)
	story_image.texture = tex
	story_image.modulate.a = 0.0

	var tween = get_tree().create_tween()
	tween.tween_property(story_image, "modulate:a", 1.0, 0.5)

func hide_image():
	var tween = get_tree().create_tween()
	tween.tween_property(story_image, "modulate:a", 0.0, 0.5)
