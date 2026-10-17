extends Node2D

## Interactive runtime check: an actual Camera2D drives procedural parallax.
## Controls/background stay in a CanvasLayer so camera movement does not
## translate the whole image a second time.
const SPACE_SCENE: PackedScene = preload("res://addons/pixel_space_background_generator/src/pixel_space_background_generator.tscn")
const DEFAULT_SPEED: float = 85.0
var generator: PixelSpaceBackgroundGenerator
var camera: Camera2D
var info: Label
var auto_move: bool = true
var speed: float = DEFAULT_SPEED
var amplitude: float = 180.0
var elapsed: float = 0.0
var _manual: Vector2 = Vector2.ZERO


func _ready() -> void:
	camera = Camera2D.new()
	camera.enabled = true
	add_child(camera)
	var layer := CanvasLayer.new()
	add_child(layer)
	var canvas := Control.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(canvas)
	generator = SPACE_SCENE.instantiate()
	generator.auto_regenerate = false
	generator.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(generator)
	generator.randomize_seed = false
	generator.manual_seed = 4200
	generator.auto_based_on_viewport_size = false
	generator.fixed_amount_of_stars = 100
	generator.fixed_amount_of_planets = 3
	generator.parallax_enabled = true
	generator.star_depth_curve = 1.7
	generator.star_depth_size = 0.55
	generator.parallax_follow_rate = 8.0
	generator.batched_stars = true
	generator.procedural_palette_enabled = true
	generator.mixed_planet_surfaces = true
	generator.planet_radius_spacing = true
	generator.planet_size_variation = 0.65
	generator.planet_organic_strength = 0.75
	generator.planet_rim_strength = 0.50
	generator.nebula_profile = 2
	generator.nebula_organic_strength = 0.65
	generator.nebula_filaments = 0.65
	generator.regenerate_current()
	var ui := VBoxContainer.new()
	ui.position = Vector2(12, 12)
	canvas.add_child(ui)
	info = Label.new()
	ui.add_child(info)
	var button_bar := HBoxContainer.new()
	ui.add_child(button_bar)
	_add_button(button_bar, "Pause / Play [Space]", _toggle_auto)
	_add_button(button_bar, "Reset [R]", reset_camera)
	_add_button(button_bar, "Export bundle", _export_bundle)
	var speed_slider := HSlider.new()
	speed_slider.custom_minimum_size = Vector2(210, 20)
	speed_slider.min_value = 10.0
	speed_slider.max_value = 260.0
	speed_slider.value = speed
	speed_slider.value_changed.connect(func(value: float) -> void: speed = value)
	ui.add_child(speed_slider)
	var amplitude_slider := HSlider.new()
	amplitude_slider.custom_minimum_size = Vector2(210, 20)
	amplitude_slider.min_value = 40.0
	amplitude_slider.max_value = 320.0
	amplitude_slider.value = amplitude
	amplitude_slider.value_changed.connect(func(value: float) -> void: amplitude = value)
	ui.add_child(amplitude_slider)
	_update_caption()


func _add_button(parent: HBoxContainer, title: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = title
	button.pressed.connect(callback)
	parent.add_child(button)


func _toggle_auto() -> void:
	auto_move = not auto_move


func reset_camera() -> void:
	_manual = Vector2.ZERO
	elapsed = 0.0
	camera.position = Vector2.ZERO
	generator.set_parallax_offset(Vector2.ZERO)
	_update_caption()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				_toggle_auto()
			KEY_R:
				reset_camera()


func _process(delta: float) -> void:
	if auto_move:
		elapsed += delta * speed / maxf(1.0, amplitude)
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	_manual += direction * delta * speed
	camera.position = _manual + Vector2(sin(elapsed), cos(elapsed * 0.7) * 0.42) * amplitude if auto_move else _manual
	generator.follow_parallax_target(camera.global_position, delta)
	_update_caption()


func _update_caption() -> void:
	if info == null or not is_instance_valid(generator):
		return
	info.text = "Parallax camera test | WASD/arrows to steer | Camera %s | seed %d | stars %d | batched %s" % [
		str(camera.global_position.round()), generator.last_seed,
		generator.get_generated_star_count(), str(generator.batched_stars)]


func _export_bundle() -> void:
	var output: String = "user://parallax_camera_test"
	var error: Error = await generator.export_parallax_bundle(output, "camera")
	if error != OK:
		push_warning(error_string(error))
	else:
		print("Bundle: ", ProjectSettings.globalize_path(output))
