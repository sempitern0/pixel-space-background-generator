@tool
class_name SpaceInfiniteParallax
extends Node2D

## Space-themed, 2-axis procedural streaming. Fixed number of visible chunks.
@export var world_seed: int = 42
@export_range(128, 2048, 32) var chunk_width: int = 512
@export_range(96, 1080, 16) var layer_height: int = 360
@export_range(0, 3, 1) var buffer_chunks: int = 1
@export_range(0.05, 2.0, 0.05) var background_speed: float = 0.15
@export_range(0.05, 2.0, 0.05) var midground_speed: float = 0.40
@export_range(0.05, 2.0, 0.05) var foreground_speed: float = 0.85
@export_enum("Open space", "Asteroid belt", "Orbital debris", "Nebula corridor", "Frozen void") var landscape_style: int = 0
@export_range(0.0, 3.0, 0.1) var object_density: float = 1.0
@export var sky_color: Color = Color("#0c1128")
@export var distant_color: Color = Color("#26375c")
@export var middle_color: Color = Color("#516a86")
@export var near_color: Color = Color("#877b8b")

var _camera_position: Vector2 = Vector2.ZERO
var _viewport_size: Vector2 = Vector2(960, 540)
var _layers: Array[Node2D] = []
var _active: Array[Dictionary] = []


func _ready() -> void:
	for i in 3:
		var layer := Node2D.new()
		layer.name = ["FarSpace", "MiddleSpace", "NearSpace"][i]
		layer.z_index = i
		add_child(layer)
		_layers.append(layer)
		_active.append({})
	update_camera(_camera_position, _viewport_size.x)


func configure(seed_value: int, width: int, height: int, style: int = 0) -> void:
	world_seed = seed_value
	chunk_width = maxi(128, width)
	layer_height = maxi(96, height)
	landscape_style = clampi(style, 0, 4)
	_refresh_all()


func _refresh_all() -> void:
	for index in _active.size():
		for segment in _active[index].values():
			var chunk: Node2D = segment
			_layers[index].remove_child(chunk)
			chunk.queue_free()
		_active[index].clear()
	if is_inside_tree():
		update_camera(_camera_position, _viewport_size.x)


## Camera in world pixels, optional viewport height for vertical shooters.
func update_camera(camera_position: Vector2, viewport_width: float, viewport_height: float = 0.0) -> void:
	_camera_position = camera_position
	var next_viewport_size := Vector2(maxf(1.0, viewport_width), maxf(1.0, viewport_height if viewport_height > 0.0 else float(layer_height)))
	# This Node2D is attached to a screen-space Control in the preview.
	# The camera offset moves only the three child layers, not their parent.
	# Never draw the sky at the camera's world coordinates: after long
	# travel that moves the rectangle off screen, exposing viewport gray.
	if next_viewport_size != _viewport_size:
		_viewport_size = next_viewport_size
		queue_redraw()
	if _layers.is_empty():
		return
	var side: int = maxi(128, chunk_width)
	for index in _layers.size():
		var speed: float = get_layer_speed(index)
		var offset: Vector2 = camera_position * speed
		var pad: float = float(buffer_chunks * side)
		var lo := Vector2i(floori((offset.x - pad) / float(side)), floori((offset.y - pad) / float(side)))
		var hi := Vector2i(floori((offset.x + _viewport_size.x + pad) / float(side)), floori((offset.y + _viewport_size.y + pad) / float(side)))
		var active: Dictionary = _active[index]
		for key in active.keys():
			var cell: Vector2i = key
			if cell.x < lo.x or cell.x > hi.x or cell.y < lo.y or cell.y > hi.y:
				var chunk: Node2D = active[key]
				_layers[index].remove_child(chunk)
				chunk.queue_free()
				active.erase(key)
		for y in range(lo.y, hi.y + 1):
			for x in range(lo.x, hi.x + 1):
				var cell := Vector2i(x, y)
				if not active.has(cell):
					var chunk := SpaceParallaxChunk.new()
					chunk.configure(world_seed, index, cell, side, landscape_style, object_density,
						[distant_color, middle_color, near_color][index])
					_layers[index].add_child(chunk)
					active[cell] = chunk
		_layers[index].position = -offset


func get_layer_speed(index: int) -> float:
	match index:
		0: return background_speed
		1: return midground_speed
		_: return foreground_speed


func get_chunk_count() -> int:
	var result: int = 0
	for entries in _active:
		result += entries.size()
	return result


func get_chunk_signature(layer_index: int, chunk_id: int, y: int = 0) -> PackedInt32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = SpaceParallaxChunk.chunk_seed(world_seed, layer_index, Vector2i(chunk_id, y))
	var output := PackedInt32Array()
	var count: int = clampi(roundi((4.0 + float(layer_index) * 3.0) * object_density), 0, 72)
	for i in count:
		rng.randf_range(14.0, float(chunk_width) - 14.0)
		rng.randf_range(14.0, float(chunk_width) - 14.0)
		var kind: int = rng.randi_range(0, 99)
		if kind < 52:
			rng.randi_range(0, 4)
			rng.randf_range(0.42, 0.94)
			output.append(0)
		elif kind < (82 if landscape_style == 1 else 72):
			output.append(1)
			# Signature records object category; seed is canonical identity.
		elif layer_index < 2 and kind > 95:
			output.append(2)
		else:
			output.append(3)
	return output


## The flat sky is always the same screen-aligned viewport rectangle.
## Infinite scrolling applies to the child content, never to this backdrop.
func get_sky_rect() -> Rect2:
	return Rect2(Vector2.ZERO, _viewport_size)


func _draw() -> void:
	draw_rect(get_sky_rect(), sky_color)
