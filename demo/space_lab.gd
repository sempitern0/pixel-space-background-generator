extends Control

const BACKGROUND_SCENE: PackedScene = preload("res://addons/pixel_space_background_generator/src/pixel_space_background_generator.tscn")
const PRESETS: Array[Dictionary] = [
	{"name": "Quiet orbit", "seed": 42, "stars": 50, "planets": 2, "clusters": 0.0, "distance": 0.0, "surface": 0, "filaments": 0.0, "coverage": 0.5},
	{"name": "Dense starfield", "seed": 117, "stars": 130, "planets": 2, "clusters": 0.9, "distance": 96.0, "surface": 2, "filaments": 0.85, "coverage": 0.7},
	{"name": "Distant systems", "seed": 902, "stars": 70, "planets": 4, "clusters": 0.65, "distance": 120.0, "surface": 3, "filaments": 0.35, "coverage": 0.35}
]
var generator: PixelSpaceBackgroundGenerator
var picker: OptionButton
var seed_input: SpinBox
var composition_toggle: CheckBox
var batch_toggle: CheckBox
var nebula_picker: OptionButton
var palette_toggle: CheckBox
var benchmark_button: Button
var status: Label


func _ready() -> void:
	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layout)
	var controls := HBoxContainer.new()
	layout.add_child(controls)
	picker = OptionButton.new()
	for preset in PRESETS:
		picker.add_item(preset["name"])
	controls.add_child(picker)
	seed_input = SpinBox.new()
	seed_input.min_value = 0
	seed_input.max_value = 2000000000
	seed_input.value = 42
	controls.add_child(seed_input)
	var generate := Button.new()
	generate.text = "Generate"
	controls.add_child(generate)
	var layers_button := Button.new()
	layers_button.text = "Export Layers"
	controls.add_child(layers_button)
	layers_button.pressed.connect(_export_layers)
	var export_button := Button.new()
	export_button.text = "Export PNG"
	controls.add_child(export_button)
	composition_toggle = CheckBox.new()
	composition_toggle.text = "Art-directed layout"
	controls.add_child(composition_toggle)
	palette_toggle = CheckBox.new()
	palette_toggle.text = "Color harmony"
	controls.add_child(palette_toggle)
	batch_toggle = CheckBox.new()
	batch_toggle.text = "Batch stars"
	controls.add_child(batch_toggle)
	nebula_picker = OptionButton.new()
	for label in ["Nebula: Classic", "Wisps", "Veils", "Cloud banks", "Void pockets"]:
		nebula_picker.add_item(label)
	controls.add_child(nebula_picker)
	benchmark_button = Button.new()
	benchmark_button.text = "Benchmark stars"
	controls.add_child(benchmark_button)
	benchmark_button.pressed.connect(_benchmark_stars)
	status = Label.new()
	layout.add_child(status)
	var stage := Control.new()
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(stage)
	generator = BACKGROUND_SCENE.instantiate()
	generator.auto_regenerate = false # The laboratory applies complete presets in one batch.
	generator.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.add_child(generator)
	picker.item_selected.connect(_select_preset)
	seed_input.value_changed.connect(func(_value: float) -> void: _generate())
	generate.pressed.connect(_generate)
	export_button.pressed.connect(_export_image)
	composition_toggle.toggled.connect(func(_enabled: bool) -> void: _generate())
	palette_toggle.toggled.connect(func(_enabled: bool) -> void: _generate())
	batch_toggle.toggled.connect(func(_enabled: bool) -> void: _generate())
	nebula_picker.item_selected.connect(func(_index: int) -> void: _generate())
	_select_preset(0)


func _select_preset(index: int) -> void:
	seed_input.value = int(PRESETS[index]["seed"])
	_generate()


func _generate() -> void:
	var preset: Dictionary = PRESETS[picker.selected]
	generator.randomize_seed = false
	generator.manual_seed = int(seed_input.value)
	generator.auto_based_on_viewport_size = false
	generator.fixed_amount_of_stars = int(preset["stars"])
	generator.fixed_amount_of_planets = int(preset["planets"])
	generator.star_cluster_strength = float(preset["clusters"])
	generator.planet_spacing = float(preset["distance"])
	generator.planet_radius_spacing = composition_toggle.button_pressed
	generator.clear_zone_radius = 0.18 if composition_toggle.button_pressed else 0.0
	generator.procedural_palette_enabled = palette_toggle.button_pressed
	generator.color_harmony = SpaceColorTheory.Harmony.AUTO
	generator.space_atmosphere = SpaceColorTheory.Atmosphere.COLD_NEBULA if picker.selected == 1 else (SpaceColorTheory.Atmosphere.EERIE_VOID if picker.selected == 2 else SpaceColorTheory.Atmosphere.DEEP_SPACE)
	generator.batched_stars = batch_toggle.button_pressed
	generator.nebula_profile = nebula_picker.selected
	generator.planet_surface = int(preset["surface"])
	generator.nebula_filaments = float(preset["filaments"])
	generator.nebula_coverage = float(preset["coverage"])
	generator.generate_new()
	status.text = "Seed %d · Stars %d · Planets %d" % [generator.manual_seed, generator.get_generated_star_count(), generator.planet_objects.size()]


func _export_image() -> void:
	var path := "user://space_%d.png" % int(seed_input.value)
	var error: Error = await generator.export_png(path)
	status.text = ProjectSettings.globalize_path(path) if error == OK else error_string(error)


func _export_layers() -> void:
	var target: String = "user://space_layers_%d" % int(seed_input.value)
	var error: Error = await generator.export_layers(target, "background")
	status.text = ProjectSettings.globalize_path(target) if error == OK else error_string(error)


## Local CPU generation comparison (does not measure GPU rendering time).
func _benchmark_stars() -> void:
	var previous_batch: bool = generator.batched_stars
	var previous_stars: int = generator.fixed_amount_of_stars
	var previous_random: bool = generator.randomize_seed
	var previous_auto: bool = generator.auto_based_on_viewport_size
	generator.auto_regenerate = false
	generator.randomize_seed = false
	generator.auto_based_on_viewport_size = false
	generator.fixed_amount_of_stars = 1000
	generator.batched_stars = false
	generator.regenerate_current()
	var legacy_ms: float = generator.last_generation_ms
	generator.batched_stars = true
	generator.regenerate_current()
	var batch_ms: float = generator.last_generation_ms
	generator.batched_stars = previous_batch
	generator.fixed_amount_of_stars = previous_stars
	generator.randomize_seed = previous_random
	generator.auto_based_on_viewport_size = previous_auto
	generator.regenerate_current()
	status.text = "CPU build 1000 stars · sprites %.2f ms · MultiMesh %.2f ms" % [legacy_ms, batch_ms]
