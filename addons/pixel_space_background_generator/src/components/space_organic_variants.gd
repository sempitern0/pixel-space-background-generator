class_name SpaceOrganicVariants
extends RefCounted

## Stateless variation: no calls to RandomNumberGenerator, so all existing
## stars, planets and shader seeds retain their replay behavior.

static func planet_phase(seed_value: int, index: int) -> float:
	return fposmod(sin(float(posmod(seed_value, 104729)) * 0.0137 + float(index + 1) * 21.137) * 12754.13, 1.0)


## Primary planet draws attention; satellites and minor planets stay smaller.
static func planet_scale_factor(seed_value: int, index: int, strength: float) -> float:
	var phase: float = planet_phase(seed_value, index)
	var target: float = lerpf(1.13, 1.55, phase) if index == 0 else lerpf(0.52, 0.95, phase)
	return lerpf(1.0, target, clampf(strength, 0.0, 1.0))
