extends Node2D
class_name Entity

@export var entity_name: String = "Unknown"
@export var sprite_path: String
@export var stats := {
	"health": 10,
	"attack": 2,
	"defense": 1
}
@export var auto_create_sprite: bool = false

func _ready():
	if auto_create_sprite and sprite_path != "":
		var sprite = Sprite2D.new()
		sprite.texture = load(sprite_path)
		add_child(sprite) 
