@tool
class_name SpaceParallaxChunk
extends Node2D

const PLANET = preload("res://addons/pixel_space_background_generator/src/components/planet.tscn")
const STAR = preload("res://addons/pixel_space_background_generator/src/components/background_star.tscn")
const NEBULA_SHADER = preload("res://addons/pixel_space_background_generator/src/shaders/nebulae.gdshader")
const DUST_SHADER = preload("res://addons/pixel_space_background_generator/src/shaders/stars.gdshader")
const PALETTE = preload("res://addons/pixel_space_background_generator/src/color_schemes/gradients/nyx8.tres")

var _seed: int
var _depth: int
var _grid: Vector2i
var _side: int
var _theme: int
var _density: float
var _tint: Color
var signature: PackedInt32Array = PackedInt32Array()


static func chunk_seed(seed_value: int, depth: int, grid: Vector2i) -> int:
	var value: int = seed_value ^ (depth * 73856093) ^ (grid.x * 19349663) ^ (grid.y * 83492791)
	return posmod(value, 2147483647)


func configure(seed_value: int, depth: int, grid: Vector2i, side: int, theme: int, density: float, tint: Color) -> void:
	_seed = seed_value
	_depth = depth
	_grid = grid
	_side = side
	_theme = theme
	_density = density
	_tint = tint
	position = Vector2(grid) * float(side)
	_build()


func _build() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = chunk_seed(_seed, _depth, _grid)
	signature = PackedInt32Array()
	if _depth == 0:
		_add_field(NEBULA_SHADER, 0.56, 0, rng)
	elif _depth == 1:
		_add_field(DUST_SHADER, 0.22, 1, rng)
	var count: int = clampi(roundi((4.0 + float(_depth) * 3.0) * _density), 0, 72)
	for i in count:
		var point := Vector2(rng.randf_range(14.0, float(_side) - 14.0), rng.randf_range(14.0, float(_side) - 14.0))
		var kind: int = rng.randi_range(0, 99)
		if kind < 52:
			_add_star(point, rng)
			signature.append(0)
		elif kind < (82 if _theme == 1 else 72):
			_add_asteroid(point, rng)
			signature.append(1)
		elif _depth < 2 and kind > 95:
			_add_planet(point, rng)
			signature.append(2)
		else:
			_add_debris(point, rng)
			signature.append(3)


func _add_field(shader: Shader, opacity: float, field_type: int, rng: RandomNumberGenerator) -> void:
	var rect := ColorRect.new()
	rect.size = Vector2.ONE * float(_side)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("streaming_mode", true)
	material.set_shader_parameter("streaming_origin", Vector2(_grid) * float(_side))
	material.set_shader_parameter("streaming_region_size", rect.size)
	material.set_shader_parameter("seed", float(posmod(_seed, 997)) * 0.008 + 1.0)
	material.set_shader_parameter("colorscheme", PALETTE.gradient)
	material.set_shader_parameter("size", 7.0 if field_type == 0 else 11.0)
	material.set_shader_parameter("OCTAVES", 3)
	material.set_shader_parameter("cloud_coverage", 0.70 if _theme == 3 else 0.42)
	material.set_shader_parameter("nebula_profile", 2 if _theme == 3 else 0)
	rect.material = material
	rect.modulate.a = opacity
	add_child(rect)


func _add_star(point: Vector2, rng: RandomNumberGenerator) -> void:
	var star := STAR.instantiate() as Sprite2D
	star.position = point
	star.configure(rng)
	star.scale = Vector2.ONE * rng.randf_range(0.42, 0.94)
	star.material.set_shader_parameter("colorscheme", PALETTE.gradient)
	add_child(star)


func _add_planet(point: Vector2, rng: RandomNumberGenerator) -> void:
	var planet := PLANET.instantiate() as Sprite2D
	planet.position = point
	planet.scale = Vector2.ONE * rng.randf_range(0.36, 0.92)
	planet.configure(rng)
	planet.material.set_shader_parameter("colorscheme", PALETTE.gradient)
	planet.material.set_shader_parameter("surface_type", rng.randi_range(0, 3))
	planet.material.set_shader_parameter("surface_detail", 0.76)
	add_child(planet)


func _add_asteroid(point: Vector2, rng: RandomNumberGenerator) -> void:
	var rock := Polygon2D.new()
	var corners: int = rng.randi_range(5, 9)
	var radius: float = rng.randf_range(6.0, 26.0) * (1.30 if _depth == 2 else 0.68)
	var phase: float = rng.randf_range(0.0, TAU)
	var points := PackedVector2Array()
	for i in corners:
		var theta: float = float(i) / float(corners) * TAU + phase
		points.append(Vector2(cos(theta), sin(theta)) * radius * rng.randf_range(0.71, 1.14))
	rock.polygon = points
	rock.color = _tint.darkened(rng.randf_range(0.05, 0.35))
	rock.position = point
	add_child(rock)
	var highlight := Line2D.new()
	highlight.width = 1.5
	highlight.default_color = _tint.lightened(0.4)
	highlight.points = PackedVector2Array([points[0], points[1], points[2]])
	rock.add_child(highlight)


func _add_debris(point: Vector2, rng: RandomNumberGenerator) -> void:
	var piece := Polygon2D.new()
	var width: float = rng.randf_range(3.0, 17.0)
	piece.polygon = PackedVector2Array([Vector2(-width, -2), Vector2(width * 0.5, -4), Vector2(width, 2), Vector2(-width * 0.5, 5)])
	piece.color = _tint.lightened(rng.randf_range(0.1, 0.38))
	piece.position = point
	piece.rotation = rng.randf_range(0.0, TAU)
	add_child(piece)
