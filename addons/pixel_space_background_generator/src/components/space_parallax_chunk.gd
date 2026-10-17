@tool
class_name SpaceParallaxChunk
extends Node2D

## One lightweight CanvasItem per chunk. Height at world X never depends on
## generation order, so adjacent chunks share exact endpoints.
var _world_seed: int
var _depth: int
var _id: int
var _width: int
var _height: int
var _style: int
var _color: Color


func configure(seed_value: int, depth: int, chunk_id: int, width: int, height: int, style: int, tint: Color) -> void:
	_world_seed = seed_value
	_depth = depth
	_id = chunk_id
	_width = width
	_height = height
	_style = style
	_color = tint
	position = Vector2(float(chunk_id * width), 0.0)
	queue_redraw()


static func _height_at(world_x: float, seed_value: int, layer: int, height: int, style: int) -> float:
	var phase: float = float(posmod(seed_value, 10007)) * 0.013 + float(layer) * 3.91
	var broad: float = sin(world_x * (0.004 + float(layer) * 0.0017) + phase)
	var detail: float = sin(world_x * (0.013 + float(layer) * 0.003) + phase * 1.73)
	var fine: float = sin(world_x * 0.036 - phase * 1.1) * sin(world_x * 0.011 + phase)
	var roughness: float = 0.10 if style == 1 else (0.31 if style == 2 else 0.20)
	return float(height) * (0.56 + broad * 0.18 + detail * roughness * 0.44 + fine * roughness * 0.25)


static func sample_heights(seed_value: int, depth: int, id: int, width: int, height: int, style: int) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	for local_x in range(0, width + 1, 8):
		result.append(_height_at(float(id * width + local_x), seed_value, depth, height, style))
	if width % 8 != 0:
		result.append(_height_at(float((id + 1) * width), seed_value, depth, height, style))
	return result


func _draw() -> void:
	var vertices := PackedVector2Array()
	vertices.append(Vector2.ZERO + Vector2(0, _height))
	var heights: PackedFloat32Array = sample_heights(_world_seed, _depth, _id, _width, _height, _style)
	for i in heights.size():
		var x: float = minf(float(i * 8), float(_width))
		if i == heights.size() - 1:
			x = float(_width)
		vertices.append(Vector2(x, heights[i]))
	vertices.append(Vector2(float(_width), float(_height)))
	draw_colored_polygon(vertices, _color)
