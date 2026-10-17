@tool
class_name PixelSpaceBackgroundGenerator extends Control

const BackgroundStarScene: PackedScene = preload("res://addons/pixel_space_background_generator/src/components/background_star.tscn")
const BackgroundPlanetScene: PackedScene = preload("res://addons/pixel_space_background_generator/src/components/planet.tscn")
const StarAtlas: Texture2D = preload("res://addons/pixel_space_background_generator/assets/textures/stars-special.png")
const BatchedStarShader: Shader = preload("res://addons/pixel_space_background_generator/src/shaders/batched_stars.gdshader")
const DefaultColorScheme: ColorGradient = preload("res://addons/pixel_space_background_generator/src/color_schemes/gradients/desert.tres")
const DefaultBackgroundColor: Color = Color("171711")

@export_tool_button("Generate New", "Reload") var generate_button: Callable = generate_new
@export var randomize_seed: bool = true:
	set(value):
		if value != randomize_seed:
			randomize_seed = value
			_update()
@export var manual_seed: int = 0:
	set(value):
		if value != manual_seed:
			manual_seed = value
			_update()
@export_category("Composition")
## 0 preserves uniform star positions. Higher values bias stars toward organic clusters.
@export_range(0.0, 1.0, 0.05) var star_cluster_strength: float = 0.0:
	set(value):
		if value != star_cluster_strength:
			star_cluster_strength = value
			_update()
## Minimum separation in pixels between planet centers (0 keeps the old behavior).
@export_range(0.0, 256.0, 1.0) var planet_spacing: float = 0.0:
	set(value):
		if value != planet_spacing:
			planet_spacing = value
			_update()
@export_range(0.0, 0.45, 0.01) var clear_zone_radius: float = 0.0:
	set(value):
		if value != clear_zone_radius:
			clear_zone_radius = value
			_update()
@export var composition_focus: Vector2 = Vector2(0.5, 0.5):
	set(value):
		if value != composition_focus:
			composition_focus = value
			_update()
@export var planet_radius_spacing: bool = false:
	set(value):
		if value != planet_radius_spacing:
			planet_radius_spacing = value
			_update()
@export_category("Color Direction")
@export var procedural_palette_enabled: bool = false:
	set(value):
		if value != procedural_palette_enabled:
			procedural_palette_enabled = value
			_update()
@export var color_harmony: SpaceColorTheory.Harmony = SpaceColorTheory.Harmony.AUTO:
	set(value):
		if value != color_harmony:
			color_harmony = value
			_update()
@export var space_atmosphere: SpaceColorTheory.Atmosphere = SpaceColorTheory.Atmosphere.DEEP_SPACE:
	set(value):
		if value != space_atmosphere:
			space_atmosphere = value
			_update()
@export_range(3, 16, 1) var palette_color_count: int = 8:
	set(value):
		if value != palette_color_count:
			palette_color_count = value
			_update()
@export_category("Depth")
@export var parallax_enabled: bool = false:
	set(value):
		if value != parallax_enabled:
			parallax_enabled = value
			_update()
@export_range(0.0, 2.0, 0.05) var far_star_factor: float = 0.12:
	set(value):
		if value != far_star_factor:
			far_star_factor = value
			_update()
@export_range(0.0, 2.0, 0.05) var near_star_factor: float = 0.65:
	set(value):
		if value != near_star_factor:
			near_star_factor = value
			_update()
@export_range(0.0, 2.0, 0.05) var planet_parallax_factor: float = 0.85:
	set(value):
		if value != planet_parallax_factor:
			planet_parallax_factor = value
			_update()
## Shader layers scroll independently from star sprites and planets.
@export_range(0.0, 2.0, 0.05) var dust_parallax_factor: float = 0.06:
	set(value):
		if value != dust_parallax_factor:
			dust_parallax_factor = value
			_update()
@export_range(0.0, 2.0, 0.05) var nebula_parallax_factor: float = 0.10:
	set(value):
		if value != nebula_parallax_factor:
			nebula_parallax_factor = value
			_update()
var _active_scheme: ColorGradient
var _parallax_offset: Vector2 = Vector2.ZERO
var _star_origin: Dictionary = {}
var _planet_origin: Dictionary = {}
var _star_batch: MultiMeshInstance2D
var _batched_positions: Array[Vector2] = []
var _batched_types: PackedInt32Array = PackedInt32Array()
var generated_star_count: int = 0
var last_seed: int = 0
var rng := RandomNumberGenerator.new()
var _prepared: bool = false
var _update_pending: bool = false
var _update_serial: int = 0
var _last_change_usec: int = 0
var _has_generated: bool = false
var _generating: bool = false
const AUTO_REFRESH_DELAY_USEC: int = 140000

@export_category("Preview")
## Setting several controls in one frame causes only one update.
@export var auto_regenerate: bool = true:
	set(value):
		if value != auto_regenerate:
			auto_regenerate = value
			if value:
				_update()
@export var tiled: bool = false:
	set(value):
		if value != tiled:
			tiled = value
			_update()
@export var tile_offset: float = 10.0:
	set(value):
		if value != tile_offset:
			tile_offset = value
			_update()
@export var reduce_background: bool = false:
	set(value):
		if value != reduce_background:
			reduce_background = value
			_update()
@export var background_color: Color = DefaultBackgroundColor:
	set(value):
		if value != background_color:
			background_color = value
			change_background_color(background_color)
@export var current_color_scheme: ColorGradient = DefaultColorScheme:
	set(value):
		if value != current_color_scheme:
			current_color_scheme = value
			_update()
@export var show_stars_behind: bool = true:
	set(value):
		if value != show_stars_behind:
			show_stars_behind = value
			_update()
@export var show_planets_behind: bool = true:
	set(value):
		if value != show_planets_behind:
			show_planets_behind = value
			_update()
@export_category("Export")
@export_dir var export_path: String = "res://space_backgrounds"
@export_tool_button("Export Background", "Image") var export_button: Callable = _export_as_image

@export_category("Stars")
## Optional high-density renderer: one MultiMesh instead of per-star Sprite2D nodes.
## Disabling it keeps the original node/texture/material behavior.
@export var batched_stars: bool = false:
	set(value):
		if value != batched_stars:
			batched_stars = value
			_update()
@export var display_stars: bool = true:
	set(value):
		if value != display_stars:
			display_stars = value
			_update()
@export var display_stars_dust: bool = true:
	set(value):
		if value != display_stars_dust:
			display_stars_dust = value
			_update()
@export var auto_based_on_viewport_size: bool = true:
	set(value):
		if auto_based_on_viewport_size != value:
			auto_based_on_viewport_size = value
			notify_property_list_changed()
			_update()
## Set to zero to calculate the amount based on the viewport size
@export var fixed_amount_of_stars: int = 0:
	set(value):
		if value != fixed_amount_of_stars:
			fixed_amount_of_stars = value
			_update()
## When fixed amount of stars is zero this value will be used on a range creation
@export var min_amount_of_stars: int = 0:
	set(value):
		if value != min_amount_of_stars:
			min_amount_of_stars = value
			_update()
## When fixed amount of stars is zero this value will be used on a range creation
@export var max_amount_of_stars: int = 0:
	set(value):
		if value != max_amount_of_stars:
			max_amount_of_stars = value
			_update()
@export_category("Planets")
@export var display_planets: bool = true:
	set(value):
		if value != display_planets:
			display_planets = value
			_update()
## Set to zero to calculate the amount based on the viewport size
@export var fixed_amount_of_planets: int = 0:
	set(value):
		if value != fixed_amount_of_planets:
			fixed_amount_of_planets = value
			_update()
## When fixed amount of planets is zero this value will be used on a range creation
@export var min_amount_of_planets: int = 0:
	set(value):
		if value != min_amount_of_planets:
			min_amount_of_planets = value
			_update()
## When fixed amount of planets is zero this value will be used on a range creation
@export var max_amount_of_planets: int = 1:
	set(value):
		if value != max_amount_of_planets:
			max_amount_of_planets = value
			_update()
@export_category("Planet surfaces")
## 0 preserves the legacy planet shader behavior.
@export_enum("Classic", "Rocky", "Gas giant", "Ice") var planet_surface: int = 0:
	set(value):
		if value != planet_surface:
			planet_surface = value
			_update()
@export_range(0.0, 1.0, 0.05) var planet_surface_detail: float = 0.65:
	set(value):
		if value != planet_surface_detail:
			planet_surface_detail = value
			_update()
## With this enabled, a scene can contain Classic, Rocky, Gas and Ice.
## Chosen by the seed and planet order, without additional RNG draws.
@export var mixed_planet_surfaces: bool = false:
	set(value):
		if value != mixed_planet_surfaces:
			mixed_planet_surfaces = value
			_update()
@export_category("Nebulae")
@export_range(0.0, 1.0, 0.05) var nebula_filaments: float = 0.0:
	set(value):
		if value != nebula_filaments:
			nebula_filaments = value
			_update()
@export_range(0.0, 1.0, 0.05) var nebula_coverage: float = 0.5:
	set(value):
		if value != nebula_coverage:
			nebula_coverage = value
			_update()
@export var display_nebulaes: bool = true:
	set(value):
		if value != display_nebulaes:
			display_nebulaes = value
			_update()

@onready var background: ColorRect = get_node_or_null("Background") if has_node("Background") else get_node_or_null("CanvasLayer/Background")
@onready var stars_dust: ColorRect = $StarsDust
@onready var nebulae: ColorRect = $Nebulae
@onready var stars_container: Node2D = $StarsContainer
@onready var planet_container: Node2D = $PlanetContainer


var planet_objects: Array[Variant] = []
var star_objects: Array[Variant] = []
var aspect: Vector2 = Vector2.ONE


func _validate_property(property: Dictionary):
	if property.name in ["fixed_amount_of_stars", "min_amount_of_stars", "max_amount_of_stars"]:
		property.usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY if auto_based_on_viewport_size else PROPERTY_USAGE_DEFAULT


func _ready() -> void:
	# Each instance owns its shader parameters. Presets stay untouched.
	stars_dust.material = stars_dust.material.duplicate()
	nebulae.material = nebulae.material.duplicate()
	# Older scenes stored the background in a viewport-wide CanvasLayer.
	if background.get_parent() != self:
		background.reparent(self, false)
	move_child(background, 0)
	background.z_index = -1
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stars_dust.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nebulae.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prepared = true
	resized.connect(on_resized)
	generate_new()


## Explicit reroll. A fresh seed is drawn only if randomize_seed is enabled.
func generate_new() -> void:
	_cancel_auto_update()
	_regenerate(true)


## Update all layers with the current selected seed.
func regenerate_current() -> void:
	_cancel_auto_update()
	_regenerate(false)


func _regenerate(new_seed: bool) -> void:
	if not _prepared:
		return
	_generating = true
	if current_color_scheme == null or current_color_scheme.gradient == null:
		current_color_scheme = DefaultColorScheme
	if new_seed or not _has_generated:
		if randomize_seed:
			rng.randomize()
			last_seed = rng.seed
		else:
			last_seed = manual_seed
	elif not randomize_seed:
		last_seed = manual_seed
	rng.seed = last_seed
	_active_scheme = SpaceColorTheory.generate(last_seed, color_harmony, space_atmosphere, palette_color_count) if procedural_palette_enabled else current_color_scheme
	_star_origin.clear()
	_planet_origin.clear()
	aspect = _calculate_aspect()
	change_background_color(background_color)
	stars_container.visible = display_stars
	stars_container.show_behind_parent = show_stars_behind
	planet_container.show_behind_parent = show_planets_behind
	nebulae.visible = display_nebulaes
	_create_stars_dust()
	_create_stars()
	_create_planets()
	_create_nebulae()
	_apply_shader_parallax()
	_has_generated = true
	_generating = false


func change_background_color(new_color: Color) -> void:
	if background:
		background.color = new_color
	
	
## Coalesce property changes while moving Inspector sliders.
func _update() -> void:
	if not auto_regenerate or not _prepared or _generating or not is_inside_tree():
		return
	_last_change_usec = Time.get_ticks_usec()
	if _update_pending:
		return
	_update_pending = true
	_update_serial += 1
	_run_auto_update.call_deferred(_update_serial)


func _cancel_auto_update() -> void:
	_update_serial += 1
	_update_pending = false


func _run_auto_update(serial: int) -> void:
	while serial == _update_serial and _update_pending and is_inside_tree():
		var remaining: int = AUTO_REFRESH_DELAY_USEC - (Time.get_ticks_usec() - _last_change_usec)
		if remaining <= 0:
			break
		await get_tree().create_timer(float(remaining) / 1000000.0).timeout
	if serial != _update_serial or not _update_pending or not is_inside_tree():
		return
	regenerate_current()


#region Stars
func _create_stars_dust() -> void:
	stars_dust.visible = display_stars_dust
	
	if display_stars_dust:
		stars_dust.material.set_shader_parameter("seed", rng.randf_range(1.0, 10.0))
		stars_dust.material.set_shader_parameter("pixels", maxf(1.0, maxf(size.x, size.y)))
		stars_dust.material.set_shader_parameter("uv_correct", aspect)
		stars_dust.material.set_shader_parameter("should_tile", tiled)
		stars_dust.material.set_shader_parameter("reduce_background", reduce_background)
		stars_dust.material.set_shader_parameter("colorscheme", _active_scheme.gradient)


func _create_stars() -> void:
	remove_stars()
	_batched_positions.clear()
	_batched_types.clear()
	generated_star_count = 0
	
	if display_stars:
		var stars_amount: int = fixed_amount_of_stars
		
		if auto_based_on_viewport_size or (fixed_amount_of_stars == 0 and min_amount_of_stars == 0 and max_amount_of_stars == 0):
			stars_amount = rng.randi() % (max(1, int(maxf(1.0, maxf(size.x, size.y)) / 20)))
		elif fixed_amount_of_stars == 0 and (min_amount_of_stars > 0 or max_amount_of_stars > 0):
			stars_amount = rng.randi_range(maxi(0, mini(min_amount_of_stars, max_amount_of_stars)), maxi(0, maxi(min_amount_of_stars, max_amount_of_stars)))
		
		for i in clampi(stars_amount, 0, 4096):
			_create_star()
		if batched_stars and not _batched_positions.is_empty():
			_create_star_batch()


func _create_star() -> void:
	var place_position: Vector2
	
	if tiled:
		place_position = Vector2(int(rng.randf_range(clampf(tile_offset, 0.0, size.x * 0.5), size.x - clampf(tile_offset, 0.0, size.x * 0.5))), int(rng.randf_range(clampf(tile_offset, 0.0, size.y * 0.5), size.y - clampf(tile_offset, 0.0, size.y * 0.5))))
	else:
		place_position = Vector2(int(rng.randf_range(0, size.x)), int(rng.randf_range(0, size.y)))
	if clear_zone_radius > 0.0:
		for clearance_try in 16:
			if SpaceComposition.outside_clear_zone(place_position, size, composition_focus, clear_zone_radius):
				break
			place_position = Vector2(int(rng.randf_range(0.0, size.x)), int(rng.randf_range(0.0, size.y)))
	if star_cluster_strength > 0.0:
		# Rejection sampling: bounded attempts and deterministic with a fixed seed.
		# A wide low-frequency wave yields regions of low and high stellar density.
		var candidate: Vector2 = place_position
		for attempt in 12:
			var field: float = (sin(candidate.x * 0.021 + float(last_seed % 1000) * 0.017) * cos(candidate.y * 0.028 - float(last_seed % 997) * 0.013) + 1.0) * 0.5
			if rng.randf() <= lerpf(1.0, 0.12 + 0.88 * field, star_cluster_strength):
				break
			candidate = Vector2(rng.randf_range(0.0, maxf(0.0, size.x)), rng.randf_range(0.0, maxf(0.0, size.y)))
		place_position = Vector2(int(candidate.x), int(candidate.y))
	if clear_zone_radius > 0.0 and not SpaceComposition.outside_clear_zone(place_position, size, composition_focus, clear_zone_radius):
		for clearance_try in 16:
			var replacement: Vector2 = Vector2(rng.randf_range(0.0, size.x), rng.randf_range(0.0, size.y))
			if SpaceComposition.outside_clear_zone(replacement, size, composition_focus, clear_zone_radius):
				place_position = replacement
				break
		if not SpaceComposition.outside_clear_zone(place_position, size, composition_focus, clear_zone_radius):
			return

	
	generated_star_count += 1
	if batched_stars:
		# Exactly one random glyph selection, matching configure() in the
		# sprite path. Switching renderers cannot change later planet seeds.
		_batched_positions.append(place_position)
		_batched_types.append(rng.randi_range(0, 4))
		return

	var background_star = BackgroundStarScene.instantiate()
	background_star.position = place_position
	background_star.configure(rng)
	background_star.material.set_shader_parameter("colorscheme", _active_scheme.gradient)
	stars_container.add_child(background_star)
	star_objects.append(background_star)
	_star_origin[background_star] = place_position
	if parallax_enabled:
		background_star.position = place_position - _parallax_offset * SpaceComposition.star_depth(last_seed, star_objects.size() - 1, far_star_factor, near_star_factor)
	


## All variants live in one atlas and one shader material. Rendering scales
## with one node rather than allocating N SceneTree nodes.
func _create_star_batch() -> void:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.use_custom_data = true
	var quad := QuadMesh.new()
	quad.size = Vector2(21.0, 21.0)
	multimesh.mesh = quad
	multimesh.instance_count = _batched_positions.size()
	for i in _batched_positions.size():
		var depth: float = SpaceComposition.star_depth(last_seed, i, far_star_factor, near_star_factor)
		multimesh.set_instance_transform_2d(i, Transform2D(0.0, _batched_positions[i]))
		multimesh.set_instance_custom_data(i, Color(float(_batched_types[i]) / 4.0, depth / 2.0, 0.0, 1.0))
	_star_batch = MultiMeshInstance2D.new()
	_star_batch.texture = StarAtlas
	_star_batch.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_star_batch.multimesh = multimesh
	var material := ShaderMaterial.new()
	material.shader = BatchedStarShader
	material.set_shader_parameter("colorscheme", _active_scheme.gradient)
	_star_batch.material = material
	stars_container.add_child(_star_batch)
	_update_star_batch_offset()


## Total number of generated stars, independent of the chosen renderer.
func get_generated_star_count() -> int:
	return generated_star_count


func _update_star_batch_offset() -> void:
	if is_instance_valid(_star_batch):
		var camera: Vector2 = _parallax_offset if parallax_enabled else Vector2.ZERO
		_star_batch.material.set_shader_parameter("camera_offset", camera)


func remove_stars() -> void:
	for star in stars_container.get_children():
		stars_container.remove_child(star)
		star.queue_free()
			
	star_objects.clear()
	_star_batch = null
	_batched_positions.clear()
	_batched_types.clear()
	generated_star_count = 0

#endregion

#region Nebulae
func _create_nebulae() -> void:
	nebulae.material.set_shader_parameter("seed", rng.randf_range(1.0, 10.0))
	nebulae.material.set_shader_parameter("pixels", maxf(1.0, maxf(size.x, size.y)))
	nebulae.material.set_shader_parameter("uv_correct", aspect)
	nebulae.material.set_shader_parameter("should_tile", tiled)
	nebulae.material.set_shader_parameter("reduce_background", reduce_background)
	nebulae.material.set_shader_parameter("colorscheme", _active_scheme.gradient)
	nebulae.material.set_shader_parameter("filament_strength", nebula_filaments)
	nebulae.material.set_shader_parameter("cloud_coverage", nebula_coverage)
	
#endregion

#region Planets
func _create_planets() -> void:
	remove_planets()
	
	planet_container.visible = display_planets
	
	if display_planets:
		var planets_amount: int = fixed_amount_of_planets
		
		if fixed_amount_of_planets == 0:
			planets_amount = rng.randi_range(maxi(0, mini(min_amount_of_planets, max_amount_of_planets)), maxi(0, maxi(min_amount_of_planets, max_amount_of_planets)))
			
		for i in clampi(planets_amount, 0, 256):
			_create_planet()
		

func _create_planet() -> void:
	var min_size = min(size.x, size.y)
	var planet_scale = Vector2.ONE * (rng.randf_range(0.2, 0.7) * rng.randf_range(0.5, 1.0) * min_size * 0.005)
	var place_position: Vector2
	var planet_radius: float = planet_scale.x * 50.0

	if (tiled):
		var planet_offset: float = planet_scale.x * 100.0 * 0.5
		place_position = Vector2(int(rng.randf_range(planet_offset, size.x - planet_offset)), int(rng.randf_range(planet_offset, size.y - planet_offset)))
	else:
		place_position = Vector2(int(rng.randf_range(0, size.x)), int(rng.randf_range(0, size.y)))
	
	if planet_spacing > 0.0 or planet_radius_spacing or clear_zone_radius > 0.0:
		var accepted: bool = false
		for attempt in 40:
			accepted = true
			if planet_radius_spacing:
				var current_planets: Array[Dictionary] = []
				for existing in planet_objects:
					current_planets.append({"center": _planet_origin[existing], "radius": float(existing.scale.x) * 50.0})
				accepted = SpaceComposition.can_place_planet(place_position, planet_radius, current_planets, planet_spacing)
			else:
				for existing in planet_objects:
					if existing.position.distance_to(place_position) < planet_spacing:
						accepted = false
						break
			if clear_zone_radius > 0.0 and not SpaceComposition.outside_clear_zone(place_position, size, composition_focus, clear_zone_radius):
				accepted = false
			if accepted:
				break
			var sampled: Vector2 = Vector2(rng.randf_range(0.0, maxf(1.0, size.x)), rng.randf_range(0.0, maxf(1.0, size.y)))
			place_position = SpaceComposition.constrain_center(sampled, planet_radius, size) if planet_radius_spacing else sampled
		if not accepted:
			return
	var planet = BackgroundPlanetScene.instantiate()
	
	planet.scale = planet_scale
	planet.position = place_position
	planet.configure(rng)
	planet.material.set_shader_parameter("colorscheme", _active_scheme.gradient)
	var surface_type: int = SpaceComposition.surface_for_planet(last_seed, planet_objects.size()) if mixed_planet_surfaces else clampi(planet_surface, 0, 3)
	planet.material.set_shader_parameter("surface_type", surface_type)
	planet.material.set_shader_parameter("surface_detail", clampf(planet_surface_detail, 0.0, 1.0))
	planet_container.add_child(planet)
	planet_objects.append(planet)
	_planet_origin[planet] = place_position
	if parallax_enabled:
		planet.position = place_position - _parallax_offset * planet_parallax_factor
	
	

func remove_planets() -> void:
	for planet in planet_container.get_children():
		planet_container.remove_child(planet)
		planet.queue_free()
			
	planet_objects.clear()
#endregion


func toggle_nebulae() -> void:
	display_nebulaes = not display_nebulaes

func toggle_stars() -> void:
	display_stars = not display_stars

func toggle_stars_dust() -> void:
	display_stars_dust = not display_stars_dust

func toggle_planets() -> void:
	display_planets = not display_planets

func _calculate_aspect() -> Vector2:
	var width := maxf(size.x, 1.0)
	var height := maxf(size.y, 1.0)
	return Vector2(width / height, 1.0) if width > height else Vector2(1.0, height / width)


## Capture only the current generated artwork, never the game's UI or editor.
## Requires a rendering backend (not --headless). Parent directory must exist.
func export_png(path: String) -> Error:
	if not _prepared or not is_inside_tree():
		return ERR_UNCONFIGURED
	if DisplayServer.get_name() == "headless":
		return ERR_UNAVAILABLE
	if size.x < 1 or size.y < 1 or size.x > 4096 or size.y > 4096:
		return ERR_INVALID_PARAMETER
	var viewport := SubViewport.new()
	viewport.size = Vector2i(size)
	viewport.disable_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	var canvas := Control.new()
	canvas.size = size
	viewport.add_child(canvas)
	# Duplicate without scripts or signals so the exact current result is preserved.
	for source in [background, stars_dust, nebulae, stars_container, planet_container]:
		var copy: CanvasItem = source.duplicate(0)
		canvas.add_child(copy)
		if copy is Control:
			copy.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(viewport)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var result := viewport.get_texture().get_image()
	var error := ERR_CANT_CREATE if result == null or result.is_empty() else result.save_png(path)
	viewport.queue_free()
	return error


## Save individual transparent PNGs for external parallax pipelines.
## Layer names: background, dust, nebula, stars and planets.
## Does not reroll the seed, and restores no scene state because it only
## renders isolated duplicates into a temporary SubViewport.
func export_layers(directory: String, prefix: String = "space") -> Error:
	if not _prepared or not is_inside_tree():
		return ERR_UNCONFIGURED
	if DisplayServer.get_name() == "headless":
		return ERR_UNAVAILABLE
	if size.x < 1.0 or size.y < 1.0 or size.x > 4096.0 or size.y > 4096.0:
		return ERR_INVALID_PARAMETER
	var error: Error = DirAccess.make_dir_recursive_absolute(directory)
	if error != OK:
		return error
	var layers: Array[CanvasItem] = [background, stars_dust, nebulae, stars_container, planet_container]
	var names: Array[String] = ["background", "dust", "nebula", "stars", "planets"]
	for i in layers.size():
		# Hidden layers remain transparent, never reactivated for an export.
		var result: Image = await _capture_layer(layers[i])
		if result == null or result.is_empty():
			return ERR_CANT_CREATE
		error = result.save_png("%s/%s_%s.png" % [directory.trim_suffix("/"), prefix, names[i]])
		if error != OK:
			return error
	return OK


func _capture_layer(source: CanvasItem) -> Image:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(size)
	viewport.disable_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	var canvas := Control.new()
	canvas.size = size
	viewport.add_child(canvas)
	var copy: CanvasItem = source.duplicate(0)
	canvas.add_child(copy)
	if copy is Control:
		copy.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(viewport)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var result: Image = viewport.get_texture().get_image()
	viewport.queue_free()
	return result


func _export_as_image() -> Error:
	var error := DirAccess.make_dir_recursive_absolute(export_path)
	if error == OK:
		var filename := "%s/%s_%s.png" % [export_path, Time.get_datetime_string_from_system().replace(":", "_"), Time.get_ticks_usec()]
		error = await export_png(filename)
	if error != OK:
		push_warning("Background export failed: %s" % error_string(error))
	elif Engine.is_editor_hint():
		EditorInterface.get_resource_filesystem().scan()
	return error


## Updates sprite positions without regenerating the seed or shaders.
func set_parallax_offset(camera_position: Vector2) -> void:
	_parallax_offset = camera_position
	_apply_shader_parallax()
	if not parallax_enabled:
		return
	for index in star_objects.size():
		var star: Node2D = star_objects[index]
		star.position = _star_origin[star] - camera_position * SpaceComposition.star_depth(last_seed, index, far_star_factor, near_star_factor)
	for planet in planet_objects:
		planet.position = _planet_origin[planet] - camera_position * planet_parallax_factor


## Full-canvas fragment shaders are scrolled by uniform, not regenerated.
## Turning parallax off restores zero offsets on the next refresh.
func _apply_shader_parallax() -> void:
	_update_star_batch_offset()
	var pixel_size: Vector2 = Vector2(maxf(1.0, size.x), maxf(1.0, size.y))
	var offset: Vector2 = -_parallax_offset / pixel_size if parallax_enabled else Vector2.ZERO
	stars_dust.material.set_shader_parameter("parallax_uv_offset", offset * dust_parallax_factor)
	nebulae.material.set_shader_parameter("parallax_uv_offset", offset * nebula_parallax_factor)


func on_resized() -> void:
	_update()
