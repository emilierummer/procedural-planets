extends Node2D

const PackedPlanetScene = preload("res://PlanetMap/Planet.tscn")

const MAX_CAMERA_ZOOM = 12.0
const MIN_CAMERA_ZOOM = 0.3
const DEFAULT_CAMERA_SPEED = 100
const TWEEN_DURATION = 0.5


@onready var PlanetInfo = %PlanetInfo
@onready var Camera: Camera2D = $Camera
@onready var Ship = $Ship


## Tracks if the camera is tracking the ship
var camera_tracking_ship: bool = true

## Stores currently visible planet nodes in the scene. The key is a string `x_y` for the planet's position
var visible_planets: Dictionary[String, Planet] = {}

## Tracks whether the planet info panel is currently open, used to disable movement and planet clicking when open
var focused_planet: bool = false

## Adds a planet node to the scene for the given planet data and stores it in visible_planets
func _add_visible_planet(planet_data: Planet) -> void:
	var planet_key = "%d_%d" % [int(planet_data.position.x), int(planet_data.position.y)]
	var planet: Area2D = PackedPlanetScene.instantiate()
	planet.position = planet_data.position
	planet.position += planet_data.position_offset
	planet.name = planet_data.name
	planet.scale = Vector2(planet_data.planet_size, planet_data.planet_size)
	var shader_seed = float(abs(hash(planet_data.position)) % 1000000) / 1000000.0
	var sprite = planet.get_node("Sprite2D") as Sprite2D
	sprite.material.set_shader_parameter("rand_seed", shader_seed)
	for param in ["atmosphere_color", "cloud_cover", "cloud_density", "cloud_color", "land_cover", "land_color_low", "land_color_high", "elevation_frequency", "elevation_strength", "elevation_contrast", "ocean_color_deep", "ocean_color_shallow", "ocean_average_depth", "ocean_depth_variation", "ocean_depth_contrast"]:
		sprite.material.set_shader_parameter(param, planet_data.get(param))
		planet.set(param, planet_data.get(param)) # Store shader parameters on the planet node for later use in the planet info panel
	planet.temperature = planet_data.temperature
	planet.planet_gravity = planet_data.planet_gravity
	planet.connect("planet_clicked", _on_planet_clicked)
	add_child(planet)
	visible_planets[planet_key] = planet


func _remove_visible_planet(planet_data: Planet) -> void:
	var key = "%d_%d" % [int(planet_data.position.x), int(planet_data.position.y)]
	if visible_planets.has(key):
		visible_planets[key].queue_free()
		visible_planets.erase(key)


func _update_visible_planets() -> void:
	var updates = PlanetGenerator.update_visible_planets()
	for planet in updates["added"]:
		_add_visible_planet(planet)
	for planet in updates["removed"]:
		_remove_visible_planet(planet)


func _ready():
	# Get original planets
	_update_visible_planets()


func _unhandled_input(event):
	if focused_planet:
		return # Don't allow movement or planet clicking when a planet is focused
	if event is InputEventScreenDrag:
		Camera.global_position -= event.relative / Camera.zoom.x # Adjust drag speed based on zoom level
		camera_tracking_ship = false # Stop tracking ship when user drags the map
	if event is InputEventMagnifyGesture:
		var new_zoom = Camera.zoom.x
		new_zoom *= event.factor
		new_zoom = clamp(new_zoom, MIN_CAMERA_ZOOM, MAX_CAMERA_ZOOM)
		if new_zoom != 0:
			Camera.zoom.x = new_zoom
			Camera.zoom.y = new_zoom
	
	_update_visible_planets()


func _process(delta):
	if focused_planet:
		return # Don't allow movement or planet clicking when a planet is focused

	var camera_speed = 8 * DEFAULT_CAMERA_SPEED / Camera.zoom.x # Adjust speed based on zoom level
	if Input.is_action_pressed("MoveUp"):
		Camera.global_position.y -= camera_speed * delta
		camera_tracking_ship = false # Stop tracking ship on user input
	if Input.is_action_pressed("MoveDown"):
		Camera.global_position.y += camera_speed * delta
		camera_tracking_ship = false # Stop tracking ship on user input
	if Input.is_action_pressed("MoveLeft"):
		Camera.global_position.x -= camera_speed * delta
		camera_tracking_ship = false # Stop tracking ship on user input
	if Input.is_action_pressed("MoveRight"):
		Camera.global_position.x += camera_speed * delta
		camera_tracking_ship = false # Stop tracking ship on user input
	
	if camera_tracking_ship:
		Camera.global_position = Ship.global_position # Update camera position to follow ship

	_update_visible_planets()


func _on_planet_clicked(planet: Planet):
	if focused_planet:
		return # Don't allow clicking another planet when one is already focused
	focused_planet = true
	# Smoothly move camera to planet position and zoom in
	var camera_tween = get_tree().create_tween()
	camera_tween.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT).tween_property(Camera, "global_position", planet.position, TWEEN_DURATION)
	camera_tween.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN).parallel().tween_property(Camera, "zoom", Vector2(MAX_CAMERA_ZOOM, MAX_CAMERA_ZOOM), TWEEN_DURATION)
	await camera_tween.finished
	PlanetInfo.update_planet_info(planet)


func _on_close_planet_info():
	# Called when the planet info panel is closed, used to re-enable movement and planet clicking
	focused_planet = false
	# Smoothly reset camera zoom
	var camera_tween = get_tree().create_tween()
	camera_tween.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT).tween_property(Camera, "zoom", Vector2(1, 1), TWEEN_DURATION)


func _on_center_camera_button_pressed():
	# Smoothly move camera to ship position
	var camera_tween = get_tree().create_tween()
	camera_tween.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT).tween_property(Camera, "global_position", Ship.global_position, TWEEN_DURATION)
	camera_tween.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT).parallel().tween_property(Camera, "zoom", Vector2(MAX_CAMERA_ZOOM, MAX_CAMERA_ZOOM), TWEEN_DURATION)
	await camera_tween.finished
	camera_tracking_ship = true
	
