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
