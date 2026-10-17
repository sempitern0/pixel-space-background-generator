@tool
class_name SpaceInfiniteParallax
extends Node2D

## Deterministic, bounded chunked 2D scrolling for platformers.
## This does not reuse the shader-based faux-3D generator: independent chunks
## are anchored in each layer's world-space coordinates.
@export var world_seed: int = 42
@export_range(128, 2048, 32) var chunk_width: int = 512
@export_range(96, 1080, 16) var layer_height: int = 360
@export_range(0, 3, 1) var buffer_chunks: int = 1
@export_range(0.05, 2.0, 0.05) var background_speed: float = 0.15
@export_range(0.05, 2.0, 0.05) var midground_speed: float = 0.40
@export_range(0.05, 2.0, 0.05) var foreground_speed: float = 0.85
@export_enum("Alien ridges", "Dunes", "Asteroid silhouettes") var landscape_style: int = 0
@export var sky_color: Color = Color("#0c1128")
@export var distant_color: Color = Color("#26375c")
@export var middle_color: Color = Color("#516a86")
@export var near_color: Color = Color("#877b8b")

var _camera_position: Vector2 = Vector2.ZERO
var _viewport_width: float = 960.0
var _layers: Array[Node2D] = []
var _active: Array[Dictionary] = []
var _time: float = 0.0


func _ready() -> void:
	if _layers.is_empty():
		for z in 3:
			var layer := Node2D.new()
			layer.name = ["Far", "Middle", "Near"][z]
			layer.z_index = z
			add_child(layer)
			_layers.append(layer)
			_active.append({})
	update_camera(Vector2.ZERO, _viewport_width)


func configure(seed_value: int, width: int, height: int, style: int = 0) -> void:
	world_seed = seed_value
	chunk_width = maxi(128, width)
	layer_height = maxi(96, height)
	landscape_style = clampi(style, 0, 2)
	_refresh_all()


func _refresh_all() -> void:
	for layer_index in _active.size():
		for segment in _active[layer_index].values():
			segment.queue_free()
		_active[layer_index].clear()
	update_camera(_camera_position, _viewport_width)


## Camera x maps into an independent continuous layer coordinate.
## Chunk ids are signed and stable for negative positions and backtracking.
func update_camera(camera_position: Vector2, viewport_width: float) -> void:
	_camera_position = camera_position
	_viewport_width = maxf(1.0, viewport_width)
	for layer_index in _layers.size():
		var speed: float = get_layer_speed(layer_index)
		var layer_x: float = camera_position.x * speed
		var left_id: int = floori((layer_x - float(chunk_width * buffer_chunks)) / float(chunk_width))
		var right_id: int = floori((layer_x + _viewport_width + float(chunk_width * buffer_chunks)) / float(chunk_width))
		var visible: Dictionary = _active[layer_index]
		for id in visible.keys():
			if int(id) < left_id or int(id) > right_id:
				var obsolete: Node2D = visible[id]
				visible.erase(id)
				obsolete.queue_free()
		for chunk_id in range(left_id, right_id + 1):
			if not visible.has(chunk_id):
				var chunk := SpaceParallaxChunk.new()
				chunk.configure(world_seed, layer_index, chunk_id, chunk_width, layer_height, landscape_style,
					[distant_color, middle_color, near_color][layer_index])
				_layers[layer_index].add_child(chunk)
				visible[chunk_id] = chunk
		_layers[layer_index].position = Vector2(-layer_x, 0.0)


func get_layer_speed(index: int) -> float:
	match index:
		0: return background_speed
		1: return midground_speed
		_: return foreground_speed


func get_chunk_count() -> int:
	var count: int = 0
	for layer in _active:
		count += layer.size()
	return count


func get_chunk_signature(layer_index: int, chunk_id: int) -> PackedFloat32Array:
	return SpaceParallaxChunk.sample_heights(world_seed, layer_index, chunk_id, chunk_width, layer_height, landscape_style)


func _draw() -> void:
	draw_rect(Rect2(Vector2(-4096, -2048), Vector2(8192, 4096)), sky_color)
