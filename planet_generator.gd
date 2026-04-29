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

# ========================================================================= #

## Distance from the edge of the screen to keep planets loaded.
const VISIBLE_BUFFER: int = 10

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

	return planet


## Updates the list of visible planets (planet_cache) based on the visible screen area.
## It generates new planets if they are not already in the cache and removes planets that are no longer visible.
func update_visible_planets() -> Dictionary:
	var updates: Dictionary = {"added": [], "removed": []}

	# Calculate screen bounds
	var canvas_transform = get_viewport().get_canvas_transform().affine_inverse()
	var screen_top_left = Vector2(0, 0)
	var world_top_left = canvas_transform * screen_top_left
	var screen_bottom_right = Vector2(get_viewport().get_visible_rect().size.x, get_viewport().get_visible_rect().size.y)
	var world_bottom_right = canvas_transform * screen_bottom_right

	# Round bounds to integers on planet grid
	world_top_left = Vector2(snapped(world_top_left.x, PLANET_GRID_SIZE), snapped(world_top_left.y, PLANET_GRID_SIZE))
	world_bottom_right = Vector2(snapped(world_bottom_right.x, PLANET_GRID_SIZE), snapped(world_bottom_right.y, PLANET_GRID_SIZE))

	# Remove planets that are no longer visible
	for key in planet_cache.keys():
		var split_key = key.split("_")
		var planet_pos = Vector2(int(split_key[0]), int(split_key[1]))
		if (planet_pos.x < world_top_left.x - VISIBLE_BUFFER
		or planet_pos.x > world_bottom_right.x + VISIBLE_BUFFER 
		or planet_pos.y < world_top_left.y - VISIBLE_BUFFER 
		or planet_pos.y > world_bottom_right.y + VISIBLE_BUFFER):
			updates["removed"].append(planet_cache[key])
			planet_cache.erase(key)

	# Generate new planets that are now visible (or still visible but not in cache)
	for x in range(world_top_left.x, world_bottom_right.x, PLANET_GRID_SIZE):
		for y in range(world_top_left.y, world_bottom_right.y, PLANET_GRID_SIZE):
			var key = "%d_%d" % [x, y]
			if not planet_cache.has(key):
				var planet = generate_planet(Vector2(x, y))
				if planet != null:
					planet_cache[key] = planet
					updates["added"].append(planet)

	return updates


## Generates a random planet name
static func generate_planet_name() -> String:
	var consonants = ["b", "c", "d", "f", "g", "h", "j", "k", "l", "m", "n", "p", "r", "s", "t", "v", "w", "z"]
	var vowels = ["a", "e", "i", "o", "u"]

	var name = ""

	if rng.randf() < START_WITH_VOWEL_CHANCE:
		name += vowels[rng.randi_range(0, vowels.size() - 1)]
	
	var syllable_roll = rng.randf()
	var syllable_count = SYLLABLE_COUNT_CHANCES.size() + 1
	var cumulative_chance = 0.0
	for i in range(SYLLABLE_COUNT_CHANCES.size()):
		cumulative_chance += SYLLABLE_COUNT_CHANCES[i]
		if syllable_roll < cumulative_chance:
			syllable_count = i + 1
			break
	for i in range(syllable_count):
		name += consonants[rng.randi_range(0, consonants.size() - 1)]
		name += vowels[rng.randi_range(0, vowels.size() - 1)]
	
	if rng.randf() < END_WITH_CONSONANT_CHANCE:
		name += consonants[rng.randi_range(0, consonants.size() - 1)]
	
	return name.capitalize()