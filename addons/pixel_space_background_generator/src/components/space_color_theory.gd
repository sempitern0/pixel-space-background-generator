class_name SpaceColorTheory
extends RefCounted

## Reproducible color harmonies for complete space scenes, not one hue per star.
## Gradients are runtime Resources owned by the generator; preset .tres files
## are never mutated.
enum Harmony { AUTO, ANALOGOUS, COMPLEMENTARY, SPLIT_COMPLEMENTARY, TRIADIC, NEUTRAL_ACCENT }
enum Atmosphere { DEEP_SPACE, COLD_NEBULA, DUSTY_GALAXY, EERIE_VOID }

const GOLDEN_CONJUGATE: float = 0.618033988749895


static func generate(seed_value: int, harmony: Harmony = Harmony.AUTO, atmosphere: Atmosphere = Atmosphere.DEEP_SPACE, count: int = 8) -> ColorGradient:
	var n: int = clampi(count, 3, 16)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ 0x5A310E
	var chosen: Harmony = harmony
	if chosen == Harmony.AUTO:
		match atmosphere:
			Atmosphere.COLD_NEBULA:
				chosen = Harmony.ANALOGOUS
			Atmosphere.DUSTY_GALAXY:
				chosen = Harmony.TRIADIC
			Atmosphere.EERIE_VOID:
				chosen = Harmony.SPLIT_COMPLEMENTARY
			_:
				chosen = Harmony.NEUTRAL_ACCENT
	# Seed-dependent bases are distributed with the golden-ratio conjugate;
	# related hues *within* the same scene use controlled harmonic intervals.
	var root_hue: float = fposmod(rng.randf() * 0.13 + float(posmod(seed_value, 997)) * GOLDEN_CONJUGATE, 1.0)
	var base_sat: float = 0.46
	match atmosphere:
		Atmosphere.DEEP_SPACE:
			root_hue = fposmod(0.63 + root_hue * 0.11, 1.0)
			base_sat = 0.48
		Atmosphere.COLD_NEBULA:
			root_hue = fposmod(0.53 + root_hue * 0.15, 1.0)
			base_sat = 0.66
		Atmosphere.DUSTY_GALAXY:
			root_hue = fposmod(0.065 + root_hue * 0.10, 1.0)
			base_sat = 0.56
		Atmosphere.EERIE_VOID:
			root_hue = fposmod(0.78 + root_hue * 0.12, 1.0)
			base_sat = 0.42
	var offsets := PackedFloat32Array()
	var colors := PackedColorArray()
	for i in n:
		var t: float = float(i) / float(n - 1)
		var hue: float = fposmod(root_hue + _hue_shift(chosen, i, n), 1.0)
		var saturation: float = base_sat
		if chosen == Harmony.NEUTRAL_ACCENT and i < n - 2:
			saturation = 0.12 + t * 0.20
		if atmosphere == Atmosphere.EERIE_VOID:
			saturation *= 0.68
		if i == n - 2:
			saturation = minf(0.85, base_sat + 0.17)
		elif i == n - 1:
			saturation = 0.12
		var brightness: float = lerpf(0.035, 0.94, pow(t, 1.42))
		colors.append(Color.from_hsv(hue, saturation, brightness))
		offsets.append(t)
	var gradient := Gradient.new()
	gradient.offsets = offsets
	gradient.colors = colors
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	texture.width = 256
	var palette := ColorGradient.new()
	palette.id = &"procedural"
	palette.name = &"Procedural harmony"
	palette.gradient = texture
	return palette


static func _hue_shift(harmony: Harmony, index: int, n: int) -> float:
	match harmony:
		Harmony.ANALOGOUS:
			return (float(index % 3) - 1.0) * 0.040
		Harmony.COMPLEMENTARY:
			return 0.50 if index % 4 >= 2 else 0.0
		Harmony.SPLIT_COMPLEMENTARY:
			return 0.42 if index % 4 == 2 else (0.58 if index % 4 == 3 else 0.0)
		Harmony.TRIADIC:
			return float(index % 3) / 3.0
		Harmony.NEUTRAL_ACCENT:
			return 0.46 if index == n - 2 else 0.0
		_:
			return 0.0
