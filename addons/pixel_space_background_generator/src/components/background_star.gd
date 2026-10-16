@tool
extends Sprite2D

## Called by the generator before entering the tree; never uses global randomness.
func configure(rng: RandomNumberGenerator) -> void:
	material = material.duplicate()
	texture = texture.duplicate()
	texture.region.position.x = 2.0 + rng.randi_range(0, 4) * 25.0
