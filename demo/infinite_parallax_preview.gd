extends Control

## Playable side-scroller preview. SpaceInfiniteParallax is a reusable runtime
## component: the camera in this demo is only an input source.
var streaming: SpaceInfiniteParallax
var info: Label
var travel: float = 0.0
var vertical: float = 0.0
var move_speed: float = 240.0
var automatic: bool = true
var style: int = 0


func _ready() -> void:
	streaming = SpaceInfiniteParallax.new()
	streaming.chunk_width = 512
	streaming.layer_height = int(get_viewport_rect().size.y)
	streaming.world_seed = 2026
	streaming.landscape_style = style
	streaming.background_speed = 0.16
	streaming.midground_speed = 0.44
	streaming.foreground_speed = 0.82
	add_child(streaming)
	var bar := HBoxContainer.new()
	bar.position = Vector2(12, 12)
	add_child(bar)
	var toggle := Button.new()
	toggle.text = "Auto / Manual [Space]"
	toggle.pressed.connect(func() -> void: automatic = not automatic)
	bar.add_child(toggle)
	var reset := Button.new()
	reset.text = "Reset [R]"
	reset.pressed.connect(func() -> void:
		travel = 0.0
		vertical = 0.0)
	bar.add_child(reset)
	var picker := OptionButton.new()
	for preset in ["Open space", "Asteroid belt", "Orbital debris", "Nebula corridor", "Frozen void"]:
		picker.add_item(preset)
	picker.item_selected.connect(func(index: int) -> void:
		style = index
		streaming.configure(streaming.world_seed, streaming.chunk_width, streaming.layer_height, style)
	)
	bar.add_child(picker)
	var slider := HSlider.new()
	slider.min_value = 20.0
	slider.max_value = 700.0
	slider.value = move_speed
	slider.custom_minimum_size = Vector2(140.0, 20.0)
	slider.value_changed.connect(func(v: float) -> void: move_speed = v)
	bar.add_child(slider)
	info = Label.new()
	info.position = Vector2(15, 55)
	add_child(info)
	streaming.update_camera(Vector2.ZERO, get_viewport_rect().size.x, get_viewport_rect().size.y)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				automatic = not automatic
			KEY_R:
				travel = 0.0
				vertical = 0.0


func _process(delta: float) -> void:
	var direction: float = Input.get_axis("ui_left", "ui_right")
	vertical += Input.get_axis("ui_up", "ui_down") * move_speed * delta
	if direction != 0.0:
		travel += direction * move_speed * delta
	elif automatic:
		travel += move_speed * delta
	streaming.update_camera(Vector2(travel, vertical), get_viewport_rect().size.x, get_viewport_rect().size.y)
	info.text = "Infinite 2D | camera X: %.0f | live chunks: %d | style: %s | arrows to steer in X/Y" % [
		travel, streaming.get_chunk_count(), ["Open space", "Asteroids", "Debris", "Nebula", "Frozen void"][style]]
