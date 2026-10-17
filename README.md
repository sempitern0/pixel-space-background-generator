<p align="center"><img src="icon.svg" width="112" alt="Pixel space background generator"></p>
<h1 align="center">Pixel Space Background Generator</h1>
<p align="center">Procedural stars, planets and nebulae for Godot 4.7.</p>

**English** · [Español](README_ES.md) · [Validation](https://github.com/sempitern0/pixel-space-background-generator/actions)

Create space backgrounds without painting each variation. Use the result live in a
2D scene or export a standalone PNG. This is a Godot port of
[Deep-Fold's space background generator](https://deep-fold.itch.io/space-background-generator).

## Start in minutes

1. Use **Godot 4.7.x**; automated checks pin **4.7.2 stable**, Compatibility renderer.
2. Copy `addons/pixel_space_background_generator/` into your project's `addons/` directory, preserving the folder name.
3. Enable the plugin in **Project → Project Settings → Plugins**.
4. Instantiate `addons/pixel_space_background_generator/src/pixel_space_background_generator.tscn` inside a Control-based scene. Give it a non-zero size.
5. Select its root and use **Generate New** in the Inspector. Choose a color gradient and toggle the layers you need.

Press **F5** for a three-preset interactive composition laboratory with seed replay and isolated PNG export; **F6** on the generator scene still shows the raw plugin example. Instantiate the supplied scene; the script expects its layer nodes.

## Choose a result you can reproduce

Disable **Randomize Seed** and set **Manual Seed** for repeatable composition.
When generating randomly, `last_seed` records the seed of the current result.
Store it along with your settings and palette to reproduce that background.

```gdscript
@onready var background: PixelSpaceBackgroundGenerator = $PixelSpaceBackgroundGenerator

func _ready() -> void:
    background.randomize_seed = false
    background.manual_seed = 42
    background.auto_based_on_viewport_size = false
    background.fixed_amount_of_stars = 24
    background.fixed_amount_of_planets = 3
    background.generate_new()
```

| Setting | Effect |
| --- | --- |
| Auto Based on Viewport Size | Chooses a star count from the available area |
| Fixed Amount | Positive values select an exact count; zero uses the configured range/automatic mode |
| Min / Max Amount | Inclusive count range; reversed or negative limits are normalized |
| Current Color Scheme | A `ColorGradient` resource with a `GradientTexture1D` |
| Display Stars / Stars Dust / Planets / Nebulaes | Independent layer switches |
| Show Stars / Planets Behind | Places those objects behind the dust and nebula layers |
| Tiled / Tile Offset | Shader tiling and object edge placement; does not guarantee seamless composite edges for every setting |
| Star Cluster Strength | Biases positions into broad uneven density regions; 0 retains uniform sampling |
| Planet Spacing | Minimum separation between planet centers; may reduce count in crowded scenes |

Parameters and resizing regenerate a preview after the current frame. For exact
control from code, set several properties then call `generate_new()`. Generated
children are transient; keep authored content outside `StarsContainer` and
`PlanetContainer`. Separate generator instances do not share writable materials.

## Export only the background

The Inspector's **Export Background** button creates the selected export directory
and writes a uniquely named PNG. It captures an isolated rendering viewport,
so editor panels, zoom and game UI are excluded. The current visual result is copied;
export does not reroll the seed.

```gdscript
# Runtime: user:// is writable in exported games.
var error := await background.export_png("user://background.png")
if error != OK:
    push_warning(error_string(error))
```

`export_png()` requires an existing parent directory and a live renderer. It returns
`ERR_UNAVAILABLE` under `--headless`, rather than waiting indefinitely. PNG size is
the generator's integer size, between 1 and 4096 pixels per dimension. Use the
Inspector's `res://space_backgrounds` default for authoring, and `user://` at runtime.

For an isolated planet PNG, create a small generator scene, disable dust, stars and
nebulae, set one planet, and use a transparent background color. Planet placement
and scale still follow the background generator's rules; this is not a dedicated
planet editor or animation exporter.

## Compatibility and validation

Version **1.3.0** targets Godot 4.7. Install the addon in `addons/pixel_space_background_generator/`; its entry files are `plugin.cfg` and `plugin.gd`. When updating an existing installation, replace the previous addon folder, update any resource references in your own scenes, and enable the plugin again. Seed reproducibility requires the same generator implementation and settings.

```sh
python3 scripts/run_tests.py --godot /path/to/godot
# With a desktop display (Linux CI uses xvfb-run):
python3 scripts/run_tests.py --godot /path/to/godot --render
```

Checks cover composition modes and repeatability, import, script compilation, deterministic generation, instance isolation,
counts, resizing, toggles and PNG export with a real OpenGL renderer. Fixed-seed
composition is reproducible within this implementation; identical shader pixels
across GPU drivers are not guaranteed. Windows, macOS and mobile hardware still
need testing on the intended device.

[Report an issue](https://github.com/sempitern0/pixel-space-background-generator/issues)
with your Godot version, platform, seed, settings and reproduction steps.

## Credits and license

Original generator and visual algorithms by [Deep-Fold](https://github.com/Deep-Fold).
Godot port maintained by [sempitern0](https://github.com/sempitern0).
See [LICENSE](LICENSE) and preserve applicable attribution when redistributing.

## Astronomical composition

**Planet Surface** chooses Classic, Rocky, Gas giant or Ice. **Planet Surface Detail** blends the selected procedural texture with the established palette and lighting. Rocky surfaces vary crust elevation, gas giants introduce warped latitude bands, and ice surfaces add bright caps and fractures. Planet color is still determined by **Current Color Scheme**; the surface type modifies terrain structure, not an astrophysical simulation.

**Nebula Filaments** introduces optional multi-frequency domain-warped filaments; **Nebula Coverage** controls the cloud mask independently of the configured gradient. At zero filaments and 0.5 coverage, the original shader behavior remains the default.

```gdscript
background.randomize_seed = false
background.manual_seed = 4242
background.planet_surface = 2 # Gas giant
background.planet_surface_detail = 0.8
background.nebula_filaments = 0.75
background.nebula_coverage = 0.6
background.star_cluster_strength = 0.8
background.planet_spacing = 96.0
background.generate_new()
var error := await background.export_png("user://gas_giant_scene.png")
```

Press **F5** to compare Quiet orbit (classic), Dense starfield (gas giants) and Distant systems (icy planets). Change the seed or export a PNG without bringing editor UI into the image. **F6** on the original addon scene remains available as the raw generator preview.

These are artistic 2D shaders with repeatable composition, **not physical orbital simulations or true 3D planets**. Every planet within one generator currently uses the selected surface family; for mixed families, combine multiple generator scenes. When seamless tiling is essential, inspect the exported composite: the legacy tile mode does not guarantee border-perfect planets or star positions.

## Art-directed composition (opt-in)

**Color harmony:** Turn on `procedural_palette_enabled` to build a deterministic `ColorGradient` for stars, planets and nebulae, with `color_harmony` (Auto, Analogous, Complementary, Split Complementary, Triadic or Neutral Accent), `space_atmosphere` (Deep Space, Cold Nebula, Dusty Galaxy, Eerie Void), and `palette_color_count` (3–16). The gradient is owned by the generator and never modifies the chosen `.tres`. If disabled, the original gradient is used unchanged.

**Composition:** `clear_zone_radius` (0–0.45 of the shorter canvas dimension) and `composition_focus` (normalized point, initially the center) keep individual stars and planet **centers** away from an intended gameplay/UI region. It is a soft composition rule: wide planets can still overlap its edge. `planet_radius_spacing` enables visible-radius-aware separation, treating the existing `planet_spacing` as an **additional edge gap** rather than a center distance. If the canvas is crowded, the generator skips a planet instead of overlapping it. Star clustering remains independent and compatible with these constraints.

**Lightweight parallax:** Set `parallax_enabled = true` and call `set_parallax_offset(camera_position)` in world/camera pixel coordinates. Stars use deterministic individual factors between `far_star_factor` and `near_star_factor`, planets use `planet_parallax_factor`. It updates their Node2D positions without generating anything new. Star dust and nebulas are still stationary shader layers in this iteration; exported PNG captures the current object offsets. Disable the feature to preserve legacy compositions. Turning it off does not automatically reset moved positions: call `set_parallax_offset(Vector2.ZERO)` before disabling.

```gdscript
@onready var space: PixelSpaceBackgroundGenerator = $PixelSpaceBackgroundGenerator

func _ready() -> void:
    space.randomize_seed = false
    space.manual_seed = 2026
    space.procedural_palette_enabled = true
    space.space_atmosphere = SpaceColorTheory.Atmosphere.COLD_NEBULA
    space.planet_radius_spacing = true
    space.clear_zone_radius = 0.17
    space.parallax_enabled = true
    space.generate_new()

func _process(_delta: float) -> void:
    space.set_parallax_offset(get_viewport().get_camera_2d().global_position)
```

The **Art-directed layout** and **Color harmony** checkboxes in `demo/space_lab.tscn` let you compare the legacy scene with the new settings at the same seed. The nebula shader also reuses an identical cloud-noise result to reduce redundant GPU work, without intentionally changing its appearance.

## Live parameter preview

**Auto Regenerate** is enabled by default. Changes in the Inspector to composition, palette, planet surfaces, nebulae, star counts, tiling or parallax configuration automatically refresh the result after a brief (~140 ms) pause. Multiple edits are coalesced, preventing a new full render for every slider event. A refresh **keeps the selected seed**, even when **Randomize Seed** is enabled. Use **Generate New** only when you want another random composition; `regenerate_current()` re-renders the same seed on demand. Changing `manual_seed` while Randomize Seed is disabled selects that seed automatically. Background color still updates directly.

For batch editing from code, temporarily set `auto_regenerate = false`, assign the properties, call `regenerate_current()`, then optionally re-enable it. The composition laboratory uses this pattern for presets; its seed input now regenerates automatically. Large scenes still incur synchronous processing during each refresh, but dragging controls does not repeatedly rebuild intermediate states.

## Layer parallax, mixed planets and PNG layers

Enable `parallax_enabled` and call `set_parallax_offset(camera_position)`: **stars, planets, stellar dust and nebulas** now scroll at independent configurable rates (`far_star_factor`, `near_star_factor`, `planet_parallax_factor`, `dust_parallax_factor`, `nebula_parallax_factor`). Dust and nebula movement is shader-based, so it does not rebuild their noise each frame. Zero offset or disabled parallax reproduces stationary layer alignment.

Set `mixed_planet_surfaces = true` to mix Classic, Rocky, Gas giant and Ice in one generated scene. The sequence rotates deterministically with seed and planet index. Leave it false to use the existing shared `planet_surface` setting.

To export five **separate** PNG layers use `await background.export_layers("user://layers", "level")`. This writes `level_background.png`, `level_dust.png`, `level_nebula.png`, `level_stars.png` and `level_planets.png`. Invisible source layers stay transparent. All five use the scene's same dimensions and current parallax offsets. The folder is created automatically. Export requires a renderer (not `--headless`), with maximum dimensions 4096×4096; the method returns an `Error`. This is useful for parallax sprites in an external game, while `export_png()` continues producing the original single composite.

## Dense stars and nebula profiles

Enable **Batched Stars** (`batched_stars = true`) for dense starfields. Instead of creating a separate `Sprite2D`, atlas texture and shader material per star, the generator uses one `MultiMeshInstance2D` with a single shader that draws the five existing star glyphs. Star choice, positions and downstream planet seeds remain deterministic. `get_generated_star_count()` reports the count in either mode. In batched mode `star_objects` is empty because the sprites no longer exist as individual nodes; use this count API instead. The MultiMesh approach reduces node overhead, but has GPU/driver trade-offs and should be measured on target hardware. It is disabled by default for existing scenes. The batched stars respect `set_parallax_offset()` and current palette shaders.

**Nebula Profile** (`nebula_profile`) offers Classic (0), Wisps (1), Veils (2), Cloud banks (3) and Void pockets (4). Each reuses the existing cloud fields with inexpensive tonal adjustments rather than additional fractal noise passes. Classic is unchanged at the shader level; other profiles deliberately alter coverage and density. Use the new **Batch stars** checkbox and nebula selector in `demo/space_lab.tscn` to compare results with the same seed.

## Performance: incremental material updates and benchmark

The automatic preview now distinguishes **structural changes** (counts, spacing, clustering, seed, atlas batching) from **visual changes** (palette and harmony, nebula profile and coverage, planet shading, layer order and parallax factors). Visual edits call `refresh_visuals()` instead of rebuilding generated stars and planets. This preserves Node2D identities and selected seeds and avoids extra calls to the generator RNG. You can also invoke `refresh_visuals()` explicitly after editing a custom gradient resource. The ~140 ms slider debounce still applies.

`last_generation_ms` records the CPU time of the most recent full scene rebuild; `last_visual_refresh_ms` records the latest incremental material update. The **Benchmark stars** button in the demo compares full CPU build times with 1,000 classic sprite stars and 1,000 batched stars, then restores the current configuration. These are **not GPU frame-time measurements**; benchmark separately on the target renderer/device before selecting your preferred strategy.

## Organic worlds, production export and live camera verification

**Organic visual controls** (all default to 0 for classic art): `planet_size_variation` builds a dominant primary planet and smaller satellites while `planet_organic_strength` bends atmospheric bands, terrain and ice patterns with seeded phases; `planet_rim_strength` adds a subtle lit edge. `nebula_organic_strength` and `nebula_flow_angle` introduce directional cloud structure while reusing sampled noise. Optional shader changes are incremental via `refresh_visuals()`; planet size hierarchy requires regeneration.

**Production export:** `await generator.export_parallax_bundle("user://space_pack", "level_01")` creates the composite `level_01.png`, five transparent/full-canvas layers (`level_01_background.png`, `_dust.png`, `_nebula.png`, `_stars.png`, `_planets.png`) and `level_01_manifest.json`, with seed, dimensions, visual options and parallax factors. Valid destinations are `user://` and `res://`, with the normal renderer requirement. The single stars layer is flattened; it does **not** preserve each star's individual depth velocity. For exact runtime parallax, instantiate this generator with the recorded seed and settings; using the exported flattened images reproduces only the coarser layer factors.

**Camera test:** Open `demo/parallax_preview.tscn` and run the scene (F6). A `Camera2D` drives `set_parallax_offset()` while a CanvasLayer keeps the canvas and controls fixed. Observe automatic sinusoidal motion, use arrows/WASD for manual steering, Space to pause, R to reset, sliders for speed/amplitude and **Export bundle** to save the currently rendered composition. The test demonstrates spatial motion, not scientific star positions or hardware benchmark FPS.

## Two parallax modes: faux 3D and infinite 2D

**Depth / faux 3D:** run `demo/parallax_preview.tscn` (F6). Existing star, planet, dust and nebula layers emulate camera depth without a physical 3D world. You can shape the star depth distribution using `star_depth_curve` (default 1) and subtle near/far size cues through `star_depth_size` (default 0, original size). Set `parallax_follow_rate` and use `follow_parallax_target(camera.global_position, delta)` to smooth rapid camera movement with frame-rate-independent exponential damping. The original `set_parallax_offset()` remains immediate for precise positioning and export.

**Infinite platformer / side-scroller:** run `demo/infinite_parallax_preview.tscn` (F6) for a separate traditional 2D scrolling landscape. The reusable `SpaceInfiniteParallax` component generates a trio of continuous procedural silhouette layers (alien ridges, dunes or asteroid-like shapes) along unbounded signed X coordinates, reuses only nearby chunks and can travel forward/backward indefinitely. Each layer uses its own `background_speed`, `midground_speed` or `foreground_speed`; all chunk boundaries are sampled at identical world coordinates, preventing geometry seams. It is not a finite image loop or a physical 3D effect. Use it as a decorative layer, not as a terrain collider.

```gdscript
var scrolling := SpaceInfiniteParallax.new()
add_child(scrolling)
scrolling.configure(2026, 512, 360, 0)
scrolling.update_camera(camera.global_position, get_viewport_rect().size.x)
```

Options include `chunk_width`, `layer_height`, `buffer_chunks`, landscape palette, preset and individual layer speeds. The camera demo lets you steer with left/right, toggle automatic travel using Space, reset using R, switch archetypes and adjust movement speed. Both demos are independent; existing generator assets, PNG exports and seeds remain backward-compatible. Godot 4.7 graphical validation is still required.

## Infinite space streaming (2D shooters)

`SpaceInfiniteParallax` now uses **existing star-atlas sprites and planet shaders, polygonal asteroids, orbital debris, and seamless world-sampled dust/nebula shaders** instead of unrelated mountain silhouettes. Chunks are deterministic, bounded in memory and stream across both X and Y, including backwards movement. Five themes: Open space, Asteroid belt, Orbital debris, Nebula corridor and Frozen void. Run `demo/infinite_parallax_preview.tscn` with F6, steer with arrows and change the theme and speed. The faux-3D mode remains independent.

```gdscript
var backdrop := SpaceInfiniteParallax.new()
add_child(backdrop)
backdrop.configure(2026, 512, 720, 1)
backdrop.update_camera(camera.global_position, viewport_size.x, viewport_size.y)
```

The assets are decorative and not physical gameplay entities. An infinite world cannot be exported into a finite PNG without specifying a capture range. Previous flat terrestrial silhouettes are retired from this mode. Godot 4.7 visual validation is still pending.

## Fix: viewport clear color after long infinite scrolling

The sky now stays fixed in **viewport-local coordinates** while streamed star/planet/debris layers move relative to the camera. This prevents Godot's gray clear color from appearing after long travel. There is no need to modify the project's clear color or reroll seeds. Check `demo/infinite_parallax_preview.tscn` at X=14,415 and beyond, negative coordinates and window resizing. The `get_sky_rect()` API lets tests verify that the sky covers `Rect2(Vector2.ZERO, viewport_size)` regardless of world travel.
