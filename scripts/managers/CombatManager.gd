extends Node
class_name CombatManager

func fight(attacker: Entity, defender: Entity) -> String:
    var damage = max(attacker.stats.attack - defender.stats.defense, 1)
    defender.stats.health -= damage
    var result = "%s hits %s for %d damage" % [attacker.entity_name, defender.entity_name, damage]

    if defender.stats.health <= 0:
        result += "\n%s is defeated!" % defender.entity_name
        defender.queue_free()
    
    return result 