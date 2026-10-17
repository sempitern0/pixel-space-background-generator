extends SceneTree

const SCENE = preload("res://addons/pixel_space_background_generator/src/pixel_space_background_generator.tscn")

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
	# Inspector-like parameter changes should coalesce into one deterministic
	# refresh and must not reroll a random seed.
	g.randomize_seed = false
	g.manual_seed = 42
	g.generate_new()
	var updates_seed: int = g.last_seed
	g.nebula_filaments = 0.25
	g.nebula_coverage = 0.65
	g.planet_surface = 1
	await create_timer(0.25).timeout
	assert(g.last_seed == updates_seed)
	assert(g.nebulae.material.get_shader_parameter("filament_strength") == 0.25)
	assert(g.nebulae.material.get_shader_parameter("cloud_coverage") == 0.65)
	g.randomize_seed = true
	g.generate_new()
	var held_seed: int = g.last_seed
	g.star_cluster_strength = 0.33
	await create_timer(0.25).timeout
	assert(g.last_seed == held_seed, "Automatic refresh unexpectedly rerolled the seed")
	g.auto_regenerate = false
	g.nebula_filaments = 0.70
	await create_timer(0.25).timeout
	assert(g.nebulae.material.get_shader_parameter("filament_strength") == 0.25)
	g.regenerate_current()
	assert(g.nebulae.material.get_shader_parameter("filament_strength") == 0.70)
	assert(g.last_seed == held_seed)
	g.auto_regenerate = true
	g.randomize_seed = false
	# A MultiMesh reduces SceneTree nodes but keeps star count, glyph
	# selection and downstream RNG decisions stable.
	g.auto_regenerate = false
	g.randomize_seed = false
	g.manual_seed = 42
	g.fixed_amount_of_stars = 96
	g.fixed_amount_of_planets = 3
	g.batched_stars = false
	g.generate_new()
	var classical_planets: Array = []
	for planet in g.planet_objects:
		classical_planets.append([planet.position, planet.scale, planet.material.get_shader_parameter("seed")])
	var classic_glyphs: PackedInt32Array = PackedInt32Array()
	for star in g.star_objects:
		classic_glyphs.append(roundi((star.texture.region.position.x - 2.0) / 25.0))
	g.batched_stars = true
	g.generate_new()
	assert(g.get_generated_star_count() == 96)
	assert(g.star_objects.size() == 0)
	assert(g.stars_container.get_child_count() == 1)
	assert(g._batched_types == classic_glyphs)
	for index in g.planet_objects.size():
		var planet = g.planet_objects[index]
		assert([planet.position, planet.scale, planet.material.get_shader_parameter("seed")] == classical_planets[index])
	g.parallax_enabled = true
	g.set_parallax_offset(Vector2(25, 10))
	assert(g._star_batch.material.get_shader_parameter("camera_offset") == Vector2(25, 10))
	g.set_parallax_offset(Vector2.ZERO)
	g.nebula_profile = 3
	g.regenerate_current()
	assert(g.nebulae.material.get_shader_parameter("nebula_profile") == 3)
	g.batched_stars = false
	g.nebula_profile = 0
	g.parallax_enabled = false
	g.regenerate_current()
	assert(g.star_objects.size() == 96)
	assert(g.nebulae.material.get_shader_parameter("nebula_profile") == 0)
	g.auto_regenerate = true
	# Purely visual updates must retain the exact star and planet instances.
	g.auto_regenerate = false
	g.randomize_seed = false
	g.manual_seed = 42
	g.fixed_amount_of_stars = 48
	g.fixed_amount_of_planets = 3
	g.batched_stars = false
	g.generate_new()
	var preserved_star: Node2D = g.star_objects[0]
	var preserved_planet: Node2D = g.planet_objects[0]
	var preserved_seed: int = g.last_seed
	var preserved_snapshot: Array = snapshot(g)
	g.nebula_profile = 2
	g.planet_surface_detail = 0.92
	g.color_harmony = SpaceColorTheory.Harmony.TRIADIC
	g.refresh_visuals()
	assert(g.star_objects[0] == preserved_star)
	assert(g.planet_objects[0] == preserved_planet)
	assert(g.last_seed == preserved_seed)
	assert(snapshot(g) == preserved_snapshot)
	assert(g.nebulae.material.get_shader_parameter("nebula_profile") == 2)
	assert(g.planet_objects[0].material.get_shader_parameter("surface_detail") == 0.92)
	g.batched_stars = true
	g.regenerate_current()
	var saved_mesh: MultiMeshInstance2D = g._star_batch
	g.far_star_factor = 0.20
	g.near_star_factor = 0.80
	g.refresh_visuals()
	assert(g._star_batch == saved_mesh)
	assert(g.last_seed == preserved_seed)
	g.batched_stars = false
	g.nebula_profile = 0
	g.regenerate_current()
	g.auto_regenerate = true
	# Infinite space: stable coordinates, signed chunk identities, bounded 2D streaming.
	var infinite := SpaceInfiniteParallax.new()
	infinite.world_seed = 241
	infinite.chunk_width = 256
	infinite.layer_height = 180
	root.add_child(infinite)
	var sig: PackedInt32Array = infinite.get_chunk_signature(1, 0, 0)
	assert(sig == infinite.get_chunk_signature(1, 0, 0))
	assert(SpaceParallaxChunk.chunk_seed(241, 0, Vector2i(-1, 0)) == SpaceParallaxChunk.chunk_seed(241, 0, Vector2i(-1, 0)))
	assert(SpaceParallaxChunk.chunk_seed(241, 0, Vector2i(-1, 0)) != SpaceParallaxChunk.chunk_seed(241, 0, Vector2i(0, 0)))
	infinite.update_camera(Vector2.ZERO, 320, 180)
	var original_count: int = infinite.get_chunk_count()
	infinite.update_camera(Vector2(80000, 70000), 320, 180)
	assert(infinite.get_chunk_count() < 100)
	infinite.update_camera(Vector2(-80000, -70000), 320, 180)
	assert(infinite.get_chunk_count() < 100)
	infinite.update_camera(Vector2.ZERO, 320, 180)
	assert(infinite.get_chunk_signature(1, 0, 0) == sig)
	assert(infinite.get_chunk_count() == original_count)
	infinite.queue_free()
	# Depth shaping and camera smoothing preserve endpoints and converge.
	g.auto_regenerate = false
	g.parallax_enabled = true
	g.star_depth_curve = 1.8
	g.star_depth_size = 0.45
	g.parallax_follow_rate = 10.0
	g.follow_parallax_target(Vector2(200, 0), 0.016)
	assert(g._parallax_offset.x > 0.0 and g._parallax_offset.x < 200.0)
	g.set_parallax_offset(Vector2.ZERO)
	g.parallax_enabled = false
	g.auto_regenerate = true
	# Optional organic parameters must replay exactly for the same seed.
	assert(is_equal_approx(SpaceOrganicVariants.planet_phase(42, 0), SpaceOrganicVariants.planet_phase(42, 0)))
	assert(SpaceOrganicVariants.planet_scale_factor(42, 0, 0.0) == 1.0)
	g.auto_regenerate = false
	g.randomize_seed = false
	g.manual_seed = 42
	g.planet_size_variation = 0.65
	g.planet_organic_strength = 0.75
	g.planet_rim_strength = 0.45
	g.nebula_organic_strength = 0.65
	g.nebula_flow_angle = 35.0
	g.fixed_amount_of_planets = 3
	g.generate_new()
	var organic_snapshot: Array = snapshot(g)
	assert(g.nebulae.material.get_shader_parameter("organic_strength") == 0.65)
	for planet in g.planet_objects:
		assert(planet.material.get_shader_parameter("organic_strength") == 0.75)
	g.generate_new()
	assert(snapshot(g) == organic_snapshot)
	g.planet_organic_strength = 0.0
	g.planet_rim_strength = 0.0
	g.planet_size_variation = 0.0
	g.nebula_organic_strength = 0.0
	g.nebula_flow_angle = 0.0
	g.regenerate_current()
	g.auto_regenerate = true
	# Mixed surfaces do not advance the generator RNG or modify other layers.
	assert(SpaceComposition.surface_for_planet(42, 0) == 2)
	assert(SpaceComposition.surface_for_planet(42, 1) == 3)
	g.mixed_planet_surfaces = true
	g.fixed_amount_of_planets = 4
	g.manual_seed = 42
	g.generate_new()
	var mixed_snapshot: Array = snapshot(g)
	for i in g.planet_objects.size():
		assert(int(g.planet_objects[i].material.get_shader_parameter("surface_type")) == SpaceComposition.surface_for_planet(42, i))
	g.generate_new()
	assert(snapshot(g) == mixed_snapshot)
	g.parallax_enabled = true
	g.set_parallax_offset(Vector2(64, 32))
	assert(g.nebulae.material.get_shader_parameter("parallax_uv_offset") != Vector2.ZERO)
	assert(g.stars_dust.material.get_shader_parameter("parallax_uv_offset") != Vector2.ZERO)
	g.parallax_enabled = false
	g.regenerate_current()
	assert(g.nebulae.material.get_shader_parameter("parallax_uv_offset") == Vector2.ZERO)
	assert(g.stars_dust.material.get_shader_parameter("parallax_uv_offset") == Vector2.ZERO)
	g.mixed_planet_surfaces = false
	# New optional art direction is deterministic, has its own gradient and
	# avoids a central gameplay area without mutating the shared preset.
	var harmonic: ColorGradient = SpaceColorTheory.generate(42, SpaceColorTheory.Harmony.AUTO, SpaceColorTheory.Atmosphere.COLD_NEBULA)
	assert(harmonic.gradient != null and harmonic.gradient.gradient.colors.size() == 8)
	assert(harmonic.gradient.gradient.colors == SpaceColorTheory.generate(42, SpaceColorTheory.Harmony.AUTO, SpaceColorTheory.Atmosphere.COLD_NEBULA).gradient.gradient.colors)
	assert(SpaceComposition.outside_clear_zone(Vector2(0, 0), Vector2(320, 180), Vector2(0.5, 0.5), 0.15))
	assert(not SpaceComposition.outside_clear_zone(Vector2(160, 90), Vector2(320, 180), Vector2(0.5, 0.5), 0.15))
	var simulated_planets: Array[Dictionary] = [{"center": Vector2(50, 50), "radius": 15.0}]
	assert(not SpaceComposition.can_place_planet(Vector2(78, 50), 12.0, simulated_planets, 5.0))
	assert(SpaceComposition.can_place_planet(Vector2(90, 50), 12.0, simulated_planets, 5.0))
	g.procedural_palette_enabled = true
	g.space_atmosphere = SpaceColorTheory.Atmosphere.COLD_NEBULA
	g.clear_zone_radius = 0.15
	g.planet_radius_spacing = true
	g.planet_spacing = 6.0
	g.fixed_amount_of_stars = 12
	g.fixed_amount_of_planets = 3
	g.manual_seed = 42
	g.generate_new()
	var harmonic_snapshot: Array = snapshot(g)
	var palette_before: ColorGradient = g._active_scheme
	g.generate_new()
	assert(snapshot(g) == harmonic_snapshot)
	assert(g._active_scheme.gradient.gradient.colors == palette_before.gradient.gradient.colors)
	for star in g.star_objects:
		assert(SpaceComposition.outside_clear_zone(star.position, g.size, g.composition_focus, g.clear_zone_radius))
	g.parallax_enabled = true
	var originals: Array = []
	for star in g.star_objects:
		originals.append(star.position)
	g.set_parallax_offset(Vector2(40, 20))
	if g.star_objects.size() > 0:
		assert(g.star_objects[0].position != originals[0])
	g.set_parallax_offset(Vector2.ZERO)
	for i in g.star_objects.size():
		assert(g.star_objects[i].position == originals[i])
	g.parallax_enabled = false
	g.procedural_palette_enabled = false
	g.clear_zone_radius = 0.0
	g.planet_radius_spacing = false
	# New composition modes must replay deterministically and obey separation.
	g.star_cluster_strength = 0.85
	g.planet_spacing = 42.0
	g.fixed_amount_of_planets = 5
	g.manual_seed = 42
	g.generate_new()
	var composed: Array = snapshot(g)
	g.generate_new()
	assert(snapshot(g) == composed)
	# Surface identity, nebula structure and replay are all captured in material state.
	g.planet_surface = 2
	g.nebula_filaments = 0.8
	g.nebula_coverage = 0.7
	g.generate_new()
	assert(g.nebulae.material.get_shader_parameter("filament_strength") == 0.8)
	assert(g.nebulae.material.get_shader_parameter("cloud_coverage") == 0.7)
	for planet in g.planet_objects:
		assert(planet.material.get_shader_parameter("surface_type") == 2)
	var astronomy_snapshot: Array = snapshot(g)
	g.generate_new()
	assert(snapshot(g) == astronomy_snapshot)
	for i in g.planet_objects.size():
		for j in range(i + 1, g.planet_objects.size()):
			assert(g.planet_objects[i].position.distance_to(g.planet_objects[j].position) >= g.planet_spacing)
	g.planet_spacing = 0.0
	g.star_cluster_strength = 0.0
	g.fixed_amount_of_planets = 0
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
		assert(await g.export_layers("user://space-layers", "test") == OK)
		assert(await g.export_parallax_bundle("user://space-bundle", "galaxy") == OK)
		var manifest_path: String = "user://space-bundle/galaxy_manifest.json"
		assert(FileAccess.file_exists(manifest_path))
		var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
		assert(int(manifest["seed"]) == g.last_seed)
		assert(manifest["files"]["composite"] == "galaxy.png")
		assert(FileAccess.file_exists("user://space-bundle/galaxy.png"))
		assert(manifest["parallax"].has("nebula"))
		for layer_name in ["background", "dust", "nebula", "stars", "planets"]:
			var layer_path: String = "user://space-layers/test_%s.png" % layer_name
			assert(FileAccess.file_exists(layer_path))
			assert(Image.load_from_file(layer_path).get_size() == Vector2i(320, 180))
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
