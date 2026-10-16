@tool
extends Sprite2D

func configure(rng: RandomNumberGenerator) -> void:
	material = material.duplicate()
	material.set_shader_parameter("light_origin", Vector2(rng.randf(), rng.randf()))
	material.set_shader_parameter("seed", rng.randf_range(1.0, 10.0))
	material.set_shader_parameter("pixels", maxi(1, int(scale.x * 100)))
