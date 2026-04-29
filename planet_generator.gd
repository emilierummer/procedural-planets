extends Node

## Chance of a planet being generated at a given location (0.1 = 10% chance)
const PLANET_GENERATION_CHANCE: float = 0.1

## Distance from the edge of the screen to keep planets loaded.
const VISIBLE_BUFFER: int = 10

static var rng: RandomNumberGenerator = RandomNumberGenerator.new()

## Stores generated visible planets to avoid regenerating them when the player moves around
## The key is a string `x_y` for the planet's position
static var planet_cache: Dictionary[String, Planet] = {}


## Generates a planet at the given position. The same position will always generate the same planet.
static func generate_planet(position: Vector2) -> Planet:
	rng.seed = hash(position)

	var planet = Planet.new()
	planet.position = position
	planet.name = "Planet " + str(rng.randi_range(1, 1000))

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

	# Round bounds to integers for easier planet generation
	world_top_left = Vector2(floor(world_top_left.x), floor(world_top_left.y))
	world_bottom_right = Vector2(ceil(world_bottom_right.x), ceil(world_bottom_right.y))

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
	rng.seed = hash(world_top_left) ^ hash(world_bottom_right) # Seed based on visible area for consistency
	var planet_locations: Array[Vector2] = []
	for x in range(world_top_left.x, world_bottom_right.x, 100):
		for y in range(world_top_left.y, world_bottom_right.y, 100):
			if rng.randf() < PLANET_GENERATION_CHANCE:
				planet_locations.append(Vector2(x, y))
	for location in planet_locations:
		var key = "%d_%d" % [int(location.x), int(location.y)]
		if not planet_cache.has(key):
			var planet = generate_planet(location)
			planet_cache[key] = planet
			updates["added"].append(planet)

	return updates
