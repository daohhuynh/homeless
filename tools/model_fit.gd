extends SceneTree

## How well the kit models actually fit the lots they land on. Lot widths are
## generated and model footprints are fixed, so every modelled building is
## stretched to fit; this reports by how much, which is the number that decides
## whether the layout constants need to move or the fit code does.
##
##   godot --headless --path . --script tools/model_fit.gd
##   godot --headless --path . --script tools/model_fit.gd -- --seeds 1,7,42
##   godot --headless --path . --script tools/model_fit.gd -- --count 20 --start 500
##
## With no arguments it reports Config.TEST_SEEDS, the same seeds the invariant
## suite and the preview harness use.
##
## --headless is correct here: nothing is rendered, the models are only measured.
## Two numbers to read:
##
##   stretch  — the ratio between the horizontal scales applied to one model.
##              1.0 is undistorted. Almost all of it lands on Z, which is the
##              axis you cannot see from the sidewalk, so it is the cheap one.
##   scale    — world metres per kit unit. Against Config.KIT_METRES_PER_UNIT
##              this says whether a building came out at human scale: 2.0x means
##              storeys and doors twice the size they were drawn at.

const CityScript := preload("res://city.gd")

func _initialize() -> void:
	var seeds := _parse_seeds(OS.get_cmdline_user_args())
	if seeds.is_empty():
		printerr("no seeds — use --seeds 1,2,3 or --seeds 1-10 or --count N")
		quit(1)
		return
	_report(seeds)

func _report(seeds: Array[int]) -> void:
	print("Model fit — %d seed(s), kit unit %.1fm\n" % [
		seeds.size(), Config.KIT_METRES_PER_UNIT])

	var stretches: Array[float] = []
	var scales: Array[float] = []
	var per_model := {}
	var total_buildings := 0

	for city_seed in seeds:
		var city: Node3D = CityScript.new()
		root.add_child(city)
		city.build(city_seed)

		var placements := _placements(city)
		total_buildings += _building_count(city)
		print("seed %d — %d modelled of %d buildings" % [
			city_seed, placements.size(), _building_count(city)])
		for p in placements:
			stretches.append(p["stretch"])
			scales.append(p["scale_x"])
			scales.append(p["scale_z"])
			per_model[p["model"]] = int(per_model.get(p["model"], 0)) + 1
			print("  %-24s %-14s lot %5.1f x %5.1f  h %5.1f  scale %5.1f / %5.1f  stretch %4.2f  %s" % [
				p["name"], p["model"], p["width"], p["depth"], p["height"],
				p["scale_x"], p["scale_z"], p["stretch"],
				"faces -Z" if p["faces_negative_z"] else "faces +Z",
			])

		root.remove_child(city)
		city.free()

	if stretches.is_empty():
		print("\nNothing modelled. Config.BUILDING_MODELS covers: %s" % [
			Config.BUILDING_MODELS.keys()])
		quit(0)
		return

	stretches.sort()
	scales.sort()
	print("\n%d modelled buildings of %d, over %d seed(s)" % [
		stretches.size(), total_buildings, seeds.size()])
	print("  stretch   median %.2f   p90 %.2f   max %.2f   over 1.5x: %d of %d" % [
		_percentile(stretches, 0.5), _percentile(stretches, 0.9), stretches[-1],
		stretches.filter(func(v: float) -> bool: return v > 1.5).size(), stretches.size()])
	print("  scale     median %.1fm/unit   range %.1f .. %.1f   median oversize %.2fx" % [
		_percentile(scales, 0.5), scales[0], scales[-1],
		_percentile(scales, 0.5) / Config.KIT_METRES_PER_UNIT])

	# Which models the aspect draw actually reaches. A kit entry that never gets
	# picked is dead weight in the table, and one that gets picked half the time
	# means the lots are all one shape.
	print("\nmodels used:")
	var names: Array = per_model.keys()
	names.sort()
	for model_name in names:
		print("  %-16s %3d  %4.1f%%" % [model_name, per_model[model_name],
			100.0 * float(per_model[model_name]) / float(stretches.size())])
	quit(0)

# --- Reading the built city -------------------------------------------------
## Read off the tree rather than off the generator: what shipped into the scene
## is what the player sees, and it is the only place the chosen model is known.
func _placements(city: Node3D) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for child in city.get_children():
		if not child.has_meta(&"location_kind"):
			continue
		if not Config.BUILDING_MODELS.has(child.get_meta(&"location_kind")):
			continue
		var footprint: Rect2 = child.get_meta(&"footprint")
		for sub in child.get_children():
			if sub is CollisionShape3D or sub is Label3D or not (sub is Node3D):
				continue
			var scale: Vector3 = (sub as Node3D).scale
			out.append({
				"name": child.get_meta(&"location_name"),
				"model": sub.name,
				"width": footprint.size.x,
				"depth": footprint.size.y,
				"height": child.get_meta(&"building_height"),
				"scale_x": scale.x,
				"scale_z": scale.z,
				"stretch": maxf(scale.x / scale.z, scale.z / scale.x),
				"faces_negative_z": absf((sub as Node3D).rotation.y) < PI * 0.5,
			})
	return out

func _building_count(city: Node3D) -> int:
	var count := 0
	for child in city.get_children():
		if child.has_meta(&"location_kind"):
			count += 1
	return count

## Nearest-rank on a sorted array. No interpolation: with a few dozen samples the
## honest sample is more informative than a smoothed one.
func _percentile(sorted_values: Array[float], fraction: float) -> float:
	var index := clampi(int(fraction * float(sorted_values.size())),
		0, sorted_values.size() - 1)
	return sorted_values[index]

# --- Arguments --------------------------------------------------------------
## Same grammar as tools/preview.gd, so a seed that looks wrong in a preview can
## be pasted straight into this.
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
