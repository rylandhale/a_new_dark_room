extends Control

@onready var stoke_button = $StokeButton
@onready var wood_button = $WoodButton
@onready var fire_label = $FireLabel
@onready var wood_label = $WoodLabel

func update_labels(fire: int, wood: int) -> void:
	fire_label.text = "🔥 Fire level: %d" % fire
	wood_label.text = "🪵 Wood: %d" % wood
	stoke_button.disabled = wood <= 0
