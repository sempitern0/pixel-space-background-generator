@tool
class_name PixelSpaceBackgroundGenerator extends Control

const BackgroundStarScene: PackedScene = preload("res://addons/pixel_space_background_generator/src/components/background_star.tscn")
const BackgroundPlanetScene: PackedScene = preload("res://addons/pixel_space_background_generator/src/components/planet.tscn")
const DefaultColorScheme: ColorGradient = preload("res://addons/pixel_space_background_generator/src/color_schemes/gradients/desert.tres")
const DefaultBackgroundColor: Color = Color("171711")

@export_tool_button("Generate New", "Reload") var generate_button: Callable = generate_new
@export var randomize_seed: bool = true
@export var manual_seed: int = 0
@export_category("Composition")
## 0 preserves uniform star positions. Higher values bias stars toward organic clusters.
@export_range(0.0, 1.0, 0.05) var star_cluster_strength: float = 0.0
## Minimum separation in pixels between planet centers (0 keeps the old behavior).
@export_range(0.0, 256.0, 1.0) var planet_spacing: float = 0.0
var last_seed: int = 0
var rng := RandomNumberGenerator.new()
var _prepared: bool = false
var _update_pending: bool = false
@export var tiled: bool = false:
	set(value):
		if value != tiled:
			tiled = value
			_update()
@export var tile_offset: float = 10.0
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
@export_enum("Classic", "Rocky", "Gas giant", "Ice") var planet_surface: int = 0
@export_range(0.0, 1.0, 0.05) var planet_surface_detail: float = 0.65
@export_category("Nebulae")
@export_range(0.0, 1.0, 0.05) var nebula_filaments: float = 0.0
@export_range(0.0, 1.0, 0.05) var nebula_coverage: float = 0.5
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


func generate_new() -> void:
	_update_pending = false
	if not _prepared:
		return
	if current_color_scheme == null or current_color_scheme.gradient == null:
		current_color_scheme = DefaultColorScheme
	if randomize_seed:
		rng.randomize()
		last_seed = rng.seed
	else:
		last_seed = manual_seed
	rng.seed = last_seed
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
	
	
func change_background_color(new_color: Color) -> void:
	if background:
		background.color = new_color
	
	
func _update() -> void:
	if _prepared and not _update_pending:
		_update_pending = true
		_flush_update.call_deferred()


func _flush_update() -> void:
	if not _update_pending:
		return
	_update_pending = false
	if is_inside_tree():
		generate_new()


#region Stars
func _create_stars_dust() -> void:
	stars_dust.visible = display_stars_dust
	
	if display_stars_dust:
		stars_dust.material.set_shader_parameter("seed", rng.randf_range(1.0, 10.0))
		stars_dust.material.set_shader_parameter("pixels", maxf(1.0, maxf(size.x, size.y)))
		stars_dust.material.set_shader_parameter("uv_correct", aspect)
		stars_dust.material.set_shader_parameter("should_tile", tiled)
		stars_dust.material.set_shader_parameter("reduce_background", reduce_background)
		stars_dust.material.set_shader_parameter("colorscheme", current_color_scheme.gradient)


func _create_stars() -> void:
	remove_stars()
	
	if display_stars:
		var stars_amount: int = fixed_amount_of_stars
		
		if auto_based_on_viewport_size or (fixed_amount_of_stars == 0 and min_amount_of_stars == 0 and max_amount_of_stars == 0):
			stars_amount = rng.randi() % (max(1, int(maxf(1.0, maxf(size.x, size.y)) / 20)))
		elif fixed_amount_of_stars == 0 and (min_amount_of_stars > 0 or max_amount_of_stars > 0):
			stars_amount = rng.randi_range(maxi(0, mini(min_amount_of_stars, max_amount_of_stars)), maxi(0, maxi(min_amount_of_stars, max_amount_of_stars)))
		
		for i in clampi(stars_amount, 0, 4096):
			_create_star()


func _create_star() -> void:
	var place_position: Vector2
	
	if tiled:
		place_position = Vector2(int(rng.randf_range(clampf(tile_offset, 0.0, size.x * 0.5), size.x - clampf(tile_offset, 0.0, size.x * 0.5))), int(rng.randf_range(clampf(tile_offset, 0.0, size.y * 0.5), size.y - clampf(tile_offset, 0.0, size.y * 0.5))))
	else:
		place_position = Vector2(int(rng.randf_range(0, size.x)), int(rng.randf_range(0, size.y)))
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

	
	var background_star = BackgroundStarScene.instantiate()
	background_star.position = place_position
	background_star.configure(rng)
	background_star.material.set_shader_parameter("colorscheme", current_color_scheme.gradient)
	stars_container.add_child(background_star)
	star_objects.append(background_star)
	


func remove_stars() -> void:
	for star in stars_container.get_children():
		stars_container.remove_child(star)
		star.queue_free()
			
	star_objects.clear()
		
#endregion

#region Nebulae
func _create_nebulae() -> void:
	nebulae.material.set_shader_parameter("seed", rng.randf_range(1.0, 10.0))
	nebulae.material.set_shader_parameter("pixels", maxf(1.0, maxf(size.x, size.y)))
	nebulae.material.set_shader_parameter("uv_correct", aspect)
	nebulae.material.set_shader_parameter("should_tile", tiled)
	nebulae.material.set_shader_parameter("reduce_background", reduce_background)
	nebulae.material.set_shader_parameter("colorscheme", current_color_scheme.gradient)
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
	
	if (tiled):
		var planet_offset: float = planet_scale.x * 100.0 * 0.5
		place_position = Vector2(int(rng.randf_range(planet_offset, size.x - planet_offset)), int(rng.randf_range(planet_offset, size.y - planet_offset)))
	else:
		place_position = Vector2(int(rng.randf_range(0, size.x)), int(rng.randf_range(0, size.y)))
	
	if planet_spacing > 0.0:
		var accepted: bool = false
		for attempt in 24:
			accepted = true
			for existing in planet_objects:
				if existing.position.distance_to(place_position) < planet_spacing:
					accepted = false
					break
			if accepted:
				break
			place_position = Vector2(int(rng.randf_range(0.0, maxf(0.0, size.x))), int(rng.randf_range(0.0, maxf(0.0, size.y))))
		if not accepted:
			return
	var planet = BackgroundPlanetScene.instantiate()
	
	planet.scale = planet_scale
	planet.position = place_position
	planet.configure(rng)
	planet.material.set_shader_parameter("colorscheme", current_color_scheme.gradient)
	planet.material.set_shader_parameter("surface_type", clampi(planet_surface, 0, 3))
	planet.material.set_shader_parameter("surface_detail", clampf(planet_surface_detail, 0.0, 1.0))
	planet_container.add_child(planet)
	planet_objects.append(planet)
	
	

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


func on_resized() -> void:
	_update()
