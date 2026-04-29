extends Node2D

const PackedPlanetScene = preload("res://PlanetMap/Planet.tscn")

@onready var PlanetInfo = $PlanetInfo


## Stores currently visible planet nodes in the scene. The key is a string `x_y` for the planet's position
var visible_planets: Dictionary[String, Planet] = {}

## Adds a planet node to the scene for the given planet data and stores it in visible_planets
func _add_visible_planet(planet_data: Planet) -> void:
	var planet_key = "%d_%d" % [int(planet_data.position.x), int(planet_data.position.y)]
	var planet = PackedPlanetScene.instantiate()
	planet.position = planet_data.position
	planet.name = planet_data.name
	planet.connect("planet_clicked", _on_planet_clicked)
	add_child(planet)
	visible_planets[planet_key] = planet


func _remove_visible_planet(planet_data: Planet) -> void:
	var key = "%d_%d" % [int(planet_data.position.x), int(planet_data.position.y)]
	if visible_planets.has(key):
		visible_planets[key].queue_free()
		visible_planets.erase(key)


func _ready():
	var other_planets = get_tree().get_nodes_in_group("other_planets")
	for planet in other_planets:
		planet.connect("planet_clicked", _on_planet_clicked)
	
	var updates = PlanetGenerator.update_visible_planets()
	for planet in updates["added"]:
		_add_visible_planet(planet)
	for planet in updates["removed"]:
		_remove_visible_planet(planet)


func _on_planet_clicked(planet: Planet):
	PlanetInfo.update_planet_info(planet)
