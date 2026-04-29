extends Node2D

const PackedPlanetScene = preload("res://PlanetMap/Planet.tscn")

const MAX_CAMERA_ZOOM = 12.0
const MIN_CAMERA_ZOOM = 0.3
const DEFAULT_CAMERA_SPEED = 100


@onready var PlanetInfo = $PlanetInfo
@onready var Camera: Camera2D = $Camera


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
	# Position camera over current planet
	Camera.global_position = $CurrentPlanet.global_position

	# Get original planets	
	var updates = PlanetGenerator.update_visible_planets()
	for planet in updates["added"]:
		_add_visible_planet(planet)
	for planet in updates["removed"]:
		_remove_visible_planet(planet)


func _unhandled_input(event):
	if event is InputEventScreenDrag:
		Camera.global_position -= event.relative / Camera.zoom.x # Adjust drag speed based on zoom level
	if event is InputEventMagnifyGesture:
		var new_zoom = Camera.zoom.x
		new_zoom *= event.factor
		new_zoom = clamp(new_zoom, MIN_CAMERA_ZOOM, MAX_CAMERA_ZOOM)
		if new_zoom != 0:
			Camera.zoom.x = new_zoom
			Camera.zoom.y = new_zoom


func _process(delta):
	var camera_speed = 8 * DEFAULT_CAMERA_SPEED / Camera.zoom.x # Adjust speed based on zoom level
	if Input.is_action_pressed("MoveUp"):
		Camera.global_position.y -= camera_speed * delta
	if Input.is_action_pressed("MoveDown"):
		Camera.global_position.y += camera_speed * delta
	if Input.is_action_pressed("MoveLeft"):
		Camera.global_position.x -= camera_speed * delta
	if Input.is_action_pressed("MoveRight"):
		Camera.global_position.x += camera_speed * delta


func _on_planet_clicked(planet: Planet):
	PlanetInfo.update_planet_info(planet)
