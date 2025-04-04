extends Node

var resources = {
	"fire": 100,
	"wood": 1
}

func change_resource(resource_name: String, amount: int):
	if not resources.has(resource_name):
		return
	resources[resource_name] += amount
	if resources[resource_name] < 0:
		resources[resource_name] = 0
