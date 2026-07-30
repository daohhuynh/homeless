extends SceneTree

## Batch city preview. Renders four fixed angles of each seed and assembles a
## contact sheet, so a generation change can be judged across a dozen cities in
## one image instead of by reshuffling in game until it feels different.
##
##   godot --path . --script tools/preview.gd -- --seeds 1,7,42
##   godot --path . --script tools/preview.gd -- --seeds 100-111
##   godot --path . --script tools/preview.gd -- --count 8 --start 500
##
## With no arguments it renders Config.TEST_SEEDS, which are the same seeds the
## invariant tests use — so when a test fails you can look at what failed.
##
## Not --headless: Godot's headless mode swaps in a dummy renderer that returns
## no image at all. The tool needs a real GPU context, so it opens a small
## window, draws nothing into it, and quits. It is still non-interactive and
## still safe to run from a script.

const CityScript := preload("res://city.gd")

var _out_dir := ""
var _written: Array[String] = []

func _initialize() -> void:
	var seeds := _parse_seeds(OS.get_cmdline_user_args())
	if seeds.is_empty():
		printerr("no seeds — use --seeds 1,2,3 or --seeds 1-10 or --count N")
		quit(1)
		return
	_render_batch(seeds)

func _render_batch(seeds: Array[int]) -> void:
	_out_dir = ProjectSettings.globalize_path(Config.PREVIEW_DIR)
	DirAccess.make_dir_recursive_absolute(_out_dir)
	print("Previewing %d seed(s) into %s\n" % [seeds.size(), _out_dir])

	var stage := _build_stage()
	var city_tiles: Array[Dictionary] = []

	for city_seed in seeds:
		var started := Time.get_ticks_msec()
		var sheet := await _render_city(stage, city_seed)
		city_tiles.append({"image": sheet, "caption": "seed %d" % city_seed})
		print("  seed %-12d %4dms" % [city_seed, Time.get_ticks_msec() - started])

	var contact := await _compose(city_tiles, Config.PREVIEW_SHEET_COLUMNS)
	_save(contact, "contact_%s.png" % _batch_name(seeds))

	print("\nWrote %d file(s):" % _written.size())
	for path in _written:
		print("  " + path)
	quit(0)

# --- One city ---------------------------------------------------------------
## Renders the four angles, saves each, and returns the assembled 2x2 sheet.
func _render_city(stage: Dictionary, city_seed: int) -> Image:
	var viewport: SubViewport = stage["viewport"]
	var camera: Camera3D = stage["camera"]
	var sun: DirectionalLight3D = stage["sun"]

	var city: Node3D = CityScript.new()
	viewport.add_child(city)
	city.build(city_seed)

	var distance: float = city.extent() * Config.PREVIEW_DISTANCE_SCALE
	camera.far = distance * 3.0
	sun.directional_shadow_max_distance = \
		city.extent() * Config.PREVIEW_SHADOW_DISTANCE_SCALE

	var dir_name := "seed_%d" % city_seed
	DirAccess.make_dir_recursive_absolute(_out_dir.path_join(dir_name))

	var tiles: Array[Dictionary] = []
	for i in Config.PREVIEW_YAWS.size():
		var yaw: float = Config.PREVIEW_YAWS[i]
		_aim(camera, yaw, distance)
		var shot := await _grab(viewport)
		_save(shot, dir_name.path_join("angle_%d.png" % int(yaw)))
		tiles.append({"image": shot, "caption": "%d°" % int(yaw)})

	var sheet := await _compose(tiles, 2)
	_save(sheet, dir_name.path_join("sheet.png"))

	viewport.remove_child(city)
	city.free()
	return sheet

## Fixed compass angles at a fixed elevation, framed off the city's own extent.
## The framing must not depend on the seed's contents, or two sheets cannot be
## compared — only on how big the grid came out.
func _aim(camera: Camera3D, yaw_degrees: float, distance: float) -> void:
	var yaw := deg_to_rad(yaw_degrees)
	var elevation := deg_to_rad(Config.PREVIEW_ELEVATION)
	var at := Vector3(
		cos(elevation) * cos(yaw), sin(elevation), cos(elevation) * sin(yaw)
	) * distance
	# look_at_from_position, not look_at: on the first frame the camera is not
	# yet considered inside the tree and look_at refuses.
	camera.look_at_from_position(at, Vector3.ZERO, Vector3.UP)

# --- Stage ------------------------------------------------------------------
## The lighting and sky come out of main.tscn rather than being rebuilt here.
## A preview lit differently from the game is a preview of a different game.
func _build_stage() -> Dictionary:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(Config.PREVIEW_WIDTH, Config.PREVIEW_HEIGHT)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)

	var main: Node = load("res://main.tscn").instantiate()

	var world_environment: WorldEnvironment = main.get_node(^"WorldEnvironment")
	var environment: Environment = world_environment.environment.duplicate()
	if Config.PREVIEW_DISABLE_FOG:
		environment.fog_enabled = false
	var holder := WorldEnvironment.new()
	holder.environment = environment
	viewport.add_child(holder)

	var sun: DirectionalLight3D = main.get_node(^"Sun")
	main.remove_child(sun)
	sun.owner = null
	viewport.add_child(sun)
	main.free()

	var camera := Camera3D.new()
	camera.fov = Config.PREVIEW_FOV
	viewport.add_child(camera)

	return {"viewport": viewport, "camera": camera, "sun": sun}

## A frame requested is not a frame drawn; the first grab after a scene change
## can come back empty or half-lit.
func _grab(viewport: SubViewport) -> Image:
	for i in Config.PREVIEW_WARMUP_FRAMES:
		await process_frame
	return viewport.get_texture().get_image()

# --- Contact sheets ---------------------------------------------------------
## Composed as a real 2D scene rather than by blitting, because the captions
## are the point — an unlabelled grid of cities is a screensaver.
func _compose(tiles: Array[Dictionary], columns: int) -> Image:
	if tiles.is_empty():
		return Image.create(1, 1, false, Image.FORMAT_RGBA8)

	var tile_size: Vector2i = (tiles[0]["image"] as Image).get_size()
	var pad := Config.PREVIEW_PADDING
	var caption := Config.PREVIEW_CAPTION_HEIGHT
	var rows := int(ceil(float(tiles.size()) / float(columns)))
	var cell := Vector2i(tile_size.x, tile_size.y + caption)

	var viewport := SubViewport.new()
	viewport.size = Vector2i(
		columns * cell.x + (columns + 1) * pad,
		rows * cell.y + (rows + 1) * pad
	)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)

	var background := ColorRect.new()
	background.color = Config.PREVIEW_BACKGROUND
	background.size = viewport.size
	viewport.add_child(background)

	for i in tiles.size():
		var column := i % columns
		var row := i / columns
		var at := Vector2(
			pad + column * (cell.x + pad),
			pad + row * (cell.y + pad)
		)

		var picture := TextureRect.new()
		picture.texture = ImageTexture.create_from_image(tiles[i]["image"])
		picture.position = at
		picture.size = Vector2(tile_size)
		viewport.add_child(picture)

		var label := Label.new()
		label.text = tiles[i]["caption"]
		label.position = at + Vector2(0.0, tile_size.y)
		label.size = Vector2(tile_size.x, caption)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override(&"font_size", Config.PREVIEW_CAPTION_FONT_SIZE)
		label.add_theme_color_override(&"font_color", Config.PREVIEW_CAPTION_COLOR)
		viewport.add_child(label)

	var composed := await _grab(viewport)
	root.remove_child(viewport)
	viewport.free()
	return composed

# --- Files and arguments ----------------------------------------------------
func _save(image: Image, relative_path: String) -> void:
	var path := _out_dir.path_join(relative_path)
	var err := image.save_png(path)
	if err != OK:
		printerr("could not write %s: %s" % [path, error_string(err)])
		return
	_written.append(Config.PREVIEW_DIR.path_join(relative_path))

## Names the batch after its seeds when there are few, and by count when there
## are many, so a rerun of the same batch overwrites rather than accumulates.
func _batch_name(seeds: Array[int]) -> String:
	if seeds.size() <= 4:
		return "_".join(seeds.map(func(s: int) -> String: return str(s)))
	return "%d_seeds_%d" % [seeds.size(), seeds[0]]

## --seeds accepts commas and inclusive ranges: "1,7,20-24".
func _parse_seeds(args: PackedStringArray) -> Array[int]:
	var seeds: Array[int] = []
	var count := 0
	var start := 1

	var i := 0
	while i < args.size():
		var arg := args[i]
		var value := ""
		if arg.contains("="):
			var split := arg.split("=", true, 1)
			arg = split[0]
			value = split[1]
		elif i + 1 < args.size():
			value = args[i + 1]
			i += 1

		match arg:
			"--seeds":
				for piece in value.split(",", false):
					# Ranges only for non-negative seeds; a leading minus is a
					# sign, not a separator.
					var range_split := piece.split("-", false)
					if not piece.begins_with("-") and range_split.size() == 2:
						for s in range(int(range_split[0]), int(range_split[1]) + 1):
							seeds.append(s)
					else:
						seeds.append(int(piece))
			"--count":
				count = int(value)
			"--start":
				start = int(value)
			_:
				printerr("unknown argument: %s" % arg)
		i += 1

	if seeds.is_empty() and count > 0:
		for n in count:
			seeds.append(start + n)
	if seeds.is_empty():
		seeds.assign(Config.TEST_SEEDS)
	return seeds
