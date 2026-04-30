extends Node

# ========================================================================= #

## Chance of a planet being generated at a given location (0.1 = 10% chance)
const PLANET_GENERATION_CHANCE: float = 0.1
## Step size of planet generation grid
const PLANET_GRID_SIZE: int = 100

## Chance of a planet name having a certain number of syllables ([0.4, 0.3, 0.3] = 40% chance of 1 syllable, 30% chance of 2 syllables, 30% chance of 3 syllables)
const SYLLABLE_COUNT_CHANCES: Array[float] = [0.25, 0.4, 0.25, 0.1]
## Chance of a planet name starting with a vowel
const START_WITH_VOWEL_CHANCE: float = 0.5
## Chance of a planet name ending with a consonant
const END_WITH_CONSONANT_CHANCE: float = 0.5

## Min value for planet color luminance, used to ensure generated planets aren't too dark
const PLANET_COLOR_LUMINANCE_MIN: float = 0.35
## Max value for planet color luminance, used to ensure generated planets aren't too light
const PLANET_COLOR_LUMINANCE_MAX: float = 0.55
## Min saturation for planet colors, used to ensure generated planets aren't too dull
const PLANET_COLOR_SATURATION_MIN: float = 0.3
## Max saturation for planet colors, used to ensure generated planets aren't too vibrant
const PLANET_COLOR_SATURATION_MAX: float = 0.7
## Max hue shift for height of land colors, used to add variety while keeping colors cohesive
const PLANET_COLOR_HUE_SHIFT: float = 0.2
## Max luminance shift for height of land and ocean colors, used to add variety while keeping colors cohesive
const PLANET_COLOR_LUMINANCE_SHIFT: float = 0.1
## Min hue shift for oceans compared to land, used to ensure ocean colors are distinct from land colors
const PLANET_OCEAN_HUE_SHIFT_MIN: float = 0.25
## Max hue shift for oceans compared to land, used to ensure ocean colors are distinct from land colors
const PLANET_OCEAN_HUE_SHIFT_MAX: float = 0.75
## Max hue shift for depth of ocean colors, used to add variety while keeping colors cohesive
const OCEAN_COLOR_HUE_SHIFT: float = 0.1

# ========================================================================= #

static var rng: RandomNumberGenerator = RandomNumberGenerator.new()

## Stores generated visible planets to avoid regenerating them when the player moves around
## The key is a string `x_y` for the planet's position
static var planet_cache: Dictionary[String, Planet] = {}


## Generates a planet at the given position. The same position will always generate the same planet.
static func generate_planet(position: Vector2) -> Planet:
	rng.seed = hash(position)

	if rng.randf() > PLANET_GENERATION_CHANCE:
		return null # No planet generated at this location

	var planet = Planet.new()
	planet.position = position
	planet.name = generate_planet_name()
	var shader_params = generate_planet_shader_params()
	planet.atmosphere_color = shader_params["atmosphere_color"]
	planet.cloud_cover = shader_params["cloud_cover"]
	planet.cloud_density = shader_params["cloud_density"]
	planet.cloud_color = shader_params["cloud_color"]
	planet.land_cover = shader_params["land_cover"]
	planet.land_color_low = shader_params["land_color_low"]
	planet.land_color_high = shader_params["land_color_high"]
	planet.elevation_frequency = shader_params["elevation_frequency"]
	planet.elevation_strength = shader_params["elevation_strength"]
	planet.elevation_contrast = shader_params["elevation_contrast"]
	planet.ocean_color_deep = shader_params["ocean_color_deep"]
	planet.ocean_color_shallow = shader_params["ocean_color_shallow"]
	planet.ocean_average_depth = shader_params["ocean_average_depth"]
	planet.ocean_depth_variation = shader_params["ocean_depth_variation"]
	planet.ocean_depth_contrast = shader_params["ocean_depth_contrast"]

	return planet


## Updates the list of visible planets (planet_cache) based on the visible screen area.
## It generates new planets if they are not already in the cache and removes planets that are no longer visible.
func update_visible_planets() -> Dictionary:
	var updates: Dictionary = {"added": [], "removed": []}

	# Calculate screen bounds
	# Get the camera's visible Rect2 in world space
	var camera = get_viewport().get_camera_2d()
	var world_camera_center = camera.get_screen_center_position()
	var world_camera_size = get_viewport().get_visible_rect().size / camera.zoom

	var world_top_left = Vector2(
		world_camera_center.x - world_camera_size.x / 2,
		world_camera_center.y - world_camera_size.y / 2
	)
	var world_bottom_right = Vector2(
		world_camera_center.x + world_camera_size.x / 2,
		world_camera_center.y + world_camera_size.y / 2
	)

	# Round bounds to integers on planet grid
	world_top_left.x = snapped(world_top_left.x, PLANET_GRID_SIZE)
	world_top_left.y = snapped(world_top_left.y, PLANET_GRID_SIZE)
	world_bottom_right.x = snapped(world_bottom_right.x, PLANET_GRID_SIZE)
	world_bottom_right.y = snapped(world_bottom_right.y, PLANET_GRID_SIZE)

	# Remove planets that are no longer visible
	for key in planet_cache.keys():
		var split_key = key.split("_")
		var planet_pos = Vector2(int(split_key[0]), int(split_key[1]))
		if (planet_pos.x < world_top_left.x
		or planet_pos.x > world_bottom_right.x
		or planet_pos.y < world_top_left.y
		or planet_pos.y > world_bottom_right.y):
			if planet_cache[key] != null:
				updates["removed"].append(planet_cache[key])
			planet_cache.erase(key)

	# Generate new planets that are now visible (or still visible but not in cache)
	for x in range(world_top_left.x, world_bottom_right.x, PLANET_GRID_SIZE):
		for y in range(world_top_left.y, world_bottom_right.y, PLANET_GRID_SIZE):
			var key = "%d_%d" % [x, y]
			if not planet_cache.has(key):
				var planet = generate_planet(Vector2(x, y))
				planet_cache[key] = planet
				if planet != null:
					updates["added"].append(planet)

	return updates


## Generates a random planet name
static func generate_planet_name() -> String:
	var consonants = ["b", "c", "d", "f", "g", "h", "j", "k", "l", "m", "n", "p", "r", "s", "t", "v", "w", "z"]
	var vowels = ["a", "e", "i", "o", "u"]

	var planet_name = ""

	if rng.randf() < START_WITH_VOWEL_CHANCE:
		planet_name += vowels[rng.randi_range(0, vowels.size() - 1)]
	
	var syllable_roll = rng.randf()
	var syllable_count = SYLLABLE_COUNT_CHANCES.size() + 1
	var cumulative_chance = 0.0
	for i in range(SYLLABLE_COUNT_CHANCES.size()):
		cumulative_chance += SYLLABLE_COUNT_CHANCES[i]
		if syllable_roll < cumulative_chance:
			syllable_count = i + 1
			break
	for i in range(syllable_count):
		planet_name += consonants[rng.randi_range(0, consonants.size() - 1)]
		planet_name += vowels[rng.randi_range(0, vowels.size() - 1)]
	
	if rng.randf() < END_WITH_CONSONANT_CHANCE:
		planet_name += consonants[rng.randi_range(0, consonants.size() - 1)]
	
	return planet_name.capitalize()


static func generate_planet_shader_params() -> Dictionary:
	var params: Dictionary = {}	

	# Randomly generate base land color
	var land_color_low = Color.from_ok_hsl(
		rng.randf(), 
		rng.randf_range(PLANET_COLOR_SATURATION_MIN, PLANET_COLOR_SATURATION_MAX), 
		rng.randf_range(PLANET_COLOR_LUMINANCE_MIN, PLANET_COLOR_LUMINANCE_MAX)
	)
	# Hue shift and lighten land color to get high land color
	var land_color_high = Color.from_ok_hsl(
		fmod(land_color_low.ok_hsl_h + rng.randf_range(-PLANET_COLOR_HUE_SHIFT, PLANET_COLOR_HUE_SHIFT), 1.0),
		land_color_low.ok_hsl_s,
		min(land_color_low.ok_hsl_l + rng.randf_range(0.05, PLANET_COLOR_LUMINANCE_SHIFT), 1.0)
	)
	# Hue shift land colors to get ocean colors
	var ocean_hue_shift = rng.randf_range(PLANET_OCEAN_HUE_SHIFT_MIN, PLANET_OCEAN_HUE_SHIFT_MAX)
	var ocean_color_shallow = Color.from_ok_hsl(
		fmod(land_color_low.ok_hsl_h + ocean_hue_shift, 1.0),
		land_color_low.ok_hsl_s,
		max(land_color_low.ok_hsl_l - rng.randf_range(0.05, PLANET_COLOR_LUMINANCE_SHIFT), 0.0)
	)
	var ocean_color_deep = Color.from_ok_hsl(
		fmod(ocean_color_shallow.ok_hsl_h + rng.randf_range(-OCEAN_COLOR_HUE_SHIFT, OCEAN_COLOR_HUE_SHIFT), 1.0),
		ocean_color_shallow.ok_hsl_s,
		min(ocean_color_shallow.ok_hsl_l - rng.randf_range(0.05, PLANET_COLOR_LUMINANCE_SHIFT), 1.0)
	)
	# Mix land and ocean color to get atmosphere color
	var land_cover = rng.randf()
	var atmosphere_color = ocean_color_shallow.lerp(land_color_low, land_cover)
	# Lighten atmosphere color to get cloud color
	var cloud_color = Color.from_ok_hsl(
		atmosphere_color.ok_hsl_h,
		atmosphere_color.ok_hsl_s,
		randf_range(0.9, 1.0)
	)

	params["atmosphere_color"] = atmosphere_color

	params["cloud_cover"] = rng.randf()
	params["cloud_density"] = rng.randf()
	params["cloud_color"] = cloud_color
	
	params["land_cover"] = land_cover
	params["land_color_low"] = land_color_low
	params["land_color_high"] = land_color_high
	params["elevation_frequency"] = rng.randf_range(2.0, 16.0)
	params["elevation_strength"] = rng.randf_range(0.0, 2.0)
	params["elevation_contrast"] = rng.randf_range(0.4, 3.0)
	
	params["ocean_color_deep"] = ocean_color_deep
	params["ocean_color_shallow"] = ocean_color_shallow
	params["ocean_average_depth"] = rng.randf()
	params["ocean_depth_variation"] = rng.randf()
	params["ocean_depth_contrast"] = rng.randf_range(0.4, 3.0)
	
	return params