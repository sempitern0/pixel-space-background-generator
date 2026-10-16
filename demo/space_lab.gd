extends Control

const BACKGROUND_SCENE: PackedScene = preload("res://addons/pixel_space_background_generator/src/pixel_space_background_generator.tscn")
const PRESETS: Array[Dictionary] = [
	{"name": "Quiet orbit", "seed": 42, "stars": 50, "planets": 2, "clusters": 0.0, "distance": 0.0},
	{"name": "Dense starfield", "seed": 117, "stars": 130, "planets": 2, "clusters": 0.9, "distance": 96.0},
	{"name": "Distant systems", "seed": 902, "stars": 70, "planets": 4, "clusters": 0.65, "distance": 120.0}
]
var generator: PixelSpaceBackgroundGenerator
var picker: OptionButton
var seed_input: SpinBox
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
	var export_button := Button.new()
	export_button.text = "Export PNG"
	controls.add_child(export_button)
	status = Label.new()
	layout.add_child(status)
	var stage := Control.new()
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(stage)
	generator = BACKGROUND_SCENE.instantiate()
	generator.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.add_child(generator)
	picker.item_selected.connect(_select_preset)
	generate.pressed.connect(_generate)
	export_button.pressed.connect(_export_image)
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
	generator.generate_new()
	status.text = "Seed %d · Stars %d · Planets %d" % [generator.manual_seed, generator.star_objects.size(), generator.planet_objects.size()]


func _export_image() -> void:
	var path := "user://space_%d.png" % int(seed_input.value)
	var error: Error = await generator.export_png(path)
	status.text = ProjectSettings.globalize_path(path) if error == OK else error_string(error)
