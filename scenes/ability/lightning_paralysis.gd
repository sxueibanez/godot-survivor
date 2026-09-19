extends RefCounted

const CHANCE := 0.2
const DURATION := 0.5


static func try_apply(enemy: Node2D, enabled: bool, chance_roll: float = -1.0) -> bool:
	var velocity := enemy.get_node_or_null("VelocityComponent") as VelocityComponent
	var roll := randf() if chance_roll < 0.0 else chance_roll
	if not enabled or roll > CHANCE or velocity == null:
		return false
	velocity.apply_stun(DURATION)
	return true
