class_name SpaceComposition
extends RefCounted

## Stateless composition helpers; pure calculations for deterministic tests.

## A clean gameplay/UI region around the requested normalized focal point.
## Radius is a fraction of the shorter canvas dimension.
static func outside_clear_zone(point: Vector2, bounds: Vector2, focus: Vector2, radius_fraction: float) -> bool:
	if radius_fraction <= 0.0:
		return true
	var center: Vector2 = Vector2(clampf(focus.x, 0.0, 1.0) * bounds.x, clampf(focus.y, 0.0, 1.0) * bounds.y)
	var radius: float = clampf(radius_fraction, 0.0, 0.45) * maxf(1.0, minf(bounds.x, bounds.y))
	return point.distance_squared_to(center) >= radius * radius


## Circle-aware planet spacing. A size-independent minimum gap is useful for
## keeping gas giants and moons apart in compositions with mixed radii.
static func can_place_planet(position: Vector2, radius: float, existing: Array[Dictionary], gap: float) -> bool:
	for planet in existing:
		var center: Vector2 = planet["center"]
		var existing_radius: float = float(planet["radius"])
		var required: float = maxf(0.0, gap) + maxf(0.0, radius) + maxf(0.0, existing_radius)
		if position.distance_squared_to(center) < required * required:
			return false
	return true


static func constrain_center(position: Vector2, radius: float, bounds: Vector2) -> Vector2:
	var margin: float = maxf(0.0, radius)
	var high_x: float = maxf(margin, bounds.x - margin)
	var high_y: float = maxf(margin, bounds.y - margin)
	return Vector2(clampf(position.x, margin, high_x), clampf(position.y, margin, high_y))


## Pure, seed-dependent depth for star sprites. No changes to the generator RNG.
static func star_depth(seed_value: int, index: int, far_speed: float, near_speed: float) -> float:
	var u: float = fposmod(sin(float(index + 1) * 12.9898 + float(posmod(seed_value, 10007)) * 0.051) * 43758.5453, 1.0)
	return lerpf(far_speed, near_speed, u)
