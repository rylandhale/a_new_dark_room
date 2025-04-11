extends Control

@onready var axe_slot = $AxeSlot/AxeImage
@onready var wood_slot = $WoodSlot/WoodImage
@onready var wood_label = $WoodSlot/WoodImage/WoodLabel

func update_inventory():
	axe_slot.visible = false
	wood_slot.visible = false

	var wood_count = 0

	for item in GameState.inventory:
		if item is AxeItem:
			axe_slot.visible = true
		if item is WoodItem:
			wood_slot.visible = true
			wood_count += 1

	wood_label.text = "Wood: %d" % wood_count
