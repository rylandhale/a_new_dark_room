extends Node

var resources = {
	"fire": 100
}

var inventory: Array[Resource] = []

func change_resource(resource_name: String, amount: int):
	if not resources.has(resource_name):
		return
	resources[resource_name] += amount
	if resources[resource_name] < 0:
		resources[resource_name] = 0

func add_item(item: Resource):
	inventory.append(item)

func remove_item(item_type: String) -> bool:
	for i in inventory.size():
		if inventory[i].name == item_type:
			inventory.remove_at(i)
			return true
	return false

func count_item(item_type: String) -> int:
	var count = 0
	for item in inventory:
		if item.name == item_type:
			count += 1
	return count
