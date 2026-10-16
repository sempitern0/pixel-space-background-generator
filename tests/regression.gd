extends SceneTree

const SCENE = preload("res://addons/ninetailsrabbit.pixel_space_background_generator/src/pixel_space_background_generator.tscn")

func _initialize() -> void:
	call_deferred("run")

func snapshot(g) -> Array:
	var result: Array = [g.stars_dust.material.get_shader_parameter("seed"), g.nebulae.material.get_shader_parameter("seed")]
	for star in g.star_objects:
		result.append([star.position, star.texture.region])
	for planet in g.planet_objects:
		result.append([planet.position, planet.scale, planet.material.get_shader_parameter("seed"), planet.material.get_shader_parameter("light_origin")])
	return result

func run() -> void:
	var g = SCENE.instantiate()
	g.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	g.size = Vector2(320, 180)
	g.randomize_seed = false
	g.manual_seed = 42
	g.auto_based_on_viewport_size = false
	g.fixed_amount_of_stars = 7
	g.fixed_amount_of_planets = 0
	g.min_amount_of_planets = 2
	g.max_amount_of_planets = 2
	root.add_child(g)
	assert(g.star_objects.size() == 7 and g.planet_objects.size() == 2)
	assert(g.stars_container.get_child_count() == 7)
	var first := snapshot(g)
	seed(12345)
	var expected_random := randi()
	seed(12345)
	for i in 3:
		g.generate_new()
		assert(snapshot(g) == first)
		assert(g.stars_container.get_child_count() == 7, "Regeneration must not leave duplicate nodes")
	assert(randi() == expected_random, "Generation changed the game's random stream")
	var other = SCENE.instantiate()
	other.randomize_seed = false
	other.manual_seed = 999
	root.add_child(other)
	assert(other.stars_dust.material != g.stars_dust.material)
	assert(snapshot(g) == first, "Another generator changed this instance")
	g.manual_seed = 43
	g.generate_new()
	assert(snapshot(g) != first)
	g.randomize_seed = true
	g.generate_new()
	var random_result := snapshot(g)
	g.randomize_seed = false
	g.manual_seed = g.last_seed
	g.generate_new()
	assert(snapshot(g) == random_result, "last_seed must reproduce a random result")
	g.min_amount_of_planets = 3
	g.max_amount_of_planets = 1
	g.generate_new()
	assert(g.planet_objects.size() >= 1 and g.planet_objects.size() <= 3)
	g.size = Vector2.ZERO
	assert(g._calculate_aspect().is_finite())
	g.current_color_scheme = null
	g.generate_new()
	assert(g.current_color_scheme != null)
	g.toggle_nebulae()
	await process_frame
	assert(not g.nebulae.visible and not g.display_nebulaes)
	g.size = Vector2(320, 180)
	g.display_nebulaes = true
	g.manual_seed = 42
	g.generate_new()
	# UI covering the entire host viewport must not contaminate the export.
	var overlay := ColorRect.new()
	overlay.color = Color.MAGENTA
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)
	var exported: int = await g.export_png("user://space-test.png")
	if DisplayServer.get_name() == "headless":
		assert(exported == ERR_UNAVAILABLE)
	else:
		assert(exported == OK)
		var result := Image.load_from_file("user://space-test.png")
		assert(result.get_size() == Vector2i(320, 180))
		assert(not result.is_invisible())
		var colors: Dictionary = {}
		for y in result.get_height():
			for x in result.get_width():
				colors[result.get_pixel(x, y)] = true
		assert(colors.size() > 8, "Export must contain generated artwork, not a flat/empty image")
		assert(not colors.has(Color.MAGENTA), "Host UI leaked into export")
		# A transparent empty background should export transparent pixels.
		g.display_stars = false
		g.display_stars_dust = false
		g.display_planets = false
		g.display_nebulaes = false
		g.background_color = Color.TRANSPARENT
		g.generate_new()
		assert(await g.export_png("user://transparent-test.png") == OK)
		assert(Image.load_from_file("user://transparent-test.png").is_invisible())
		print("Exported: ", ProjectSettings.globalize_path("user://space-test.png"))
	overlay.free()
	g.free()
	other.free()
	await process_frame
	print("PASS: generator regression")
	quit()
