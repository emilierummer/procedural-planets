extends Node2D

const PackedPlanetScene = preload("res://PlanetMap/Planet.tscn")

const MAX_CAMERA_ZOOM = 12.0
const MIN_CAMERA_ZOOM = 0.3
const DEFAULT_CAMERA_SPEED = 100
const TWEEN_DURATION = 0.5


@onready var PlanetInfo = %PlanetInfo
@onready var Camera: Camera2D = $Camera


## Stores currently visible planet nodes in the scene. The key is a string `x_y` for the planet's position
var visible_planets: Dictionary[String, Planet] = {}

## Tracks whether the planet info panel is currently open, used to disable movement and planet clicking when open
var focused_planet: bool = false

## Adds a planet node to the scene for the given planet data and stores it in visible_planets
func _add_visible_planet(planet_data: Planet) -> void:
	var planet_key = "%d_%d" % [int(planet_data.position.x), int(planet_data.position.y)]
	var planet = PackedPlanetScene.instantiate()
	planet.position = planet_data.position
	planet.name = planet_data.name
	var shader_seed = float(abs(hash(planet_data.position)) % 1000000) / 1000000.0
	var sprite = planet.get_node("Sprite2D") as Sprite2D
	sprite.material.set_shader_parameter("rand_seed", shader_seed)
	sprite.material.set_shader_parameter("atmosphere_color", planet_data.atmosphere_color)
	sprite.material.set_shader_parameter("cloud_cover", planet_data.cloud_cover)
	sprite.material.set_shader_parameter("cloud_density", planet_data.cloud_density)
	sprite.material.set_shader_parameter("cloud_color", planet_data.cloud_color)
	sprite.material.set_shader_parameter("land_cover", planet_data.land_cover)
	sprite.material.set_shader_parameter("land_color_low", planet_data.land_color_low)
	sprite.material.set_shader_parameter("land_color_high", planet_data.land_color_high)
	sprite.material.set_shader_parameter("elevation_frequency", planet_data.elevation_frequency)
	sprite.material.set_shader_parameter("elevation_strength", planet_data.elevation_strength)
	sprite.material.set_shader_parameter("elevation_contrast", planet_data.elevation_contrast)
	sprite.material.set_shader_parameter("ocean_color_deep", planet_data.ocean_color_deep)
	sprite.material.set_shader_parameter("ocean_color_shallow", planet_data.ocean_color_shallow)
	sprite.material.set_shader_parameter("ocean_average_depth", planet_data.ocean_average_depth)
	sprite.material.set_shader_parameter("ocean_depth_variation", planet_data.ocean_depth_variation)
	sprite.material.set_shader_parameter("ocean_depth_contrast", planet_data.ocean_depth_contrast)
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
	if Input.is_action_pressed("MoveDown"):
		Camera.global_position.y += camera_speed * delta
	if Input.is_action_pressed("MoveLeft"):
		Camera.global_position.x -= camera_speed * delta
	if Input.is_action_pressed("MoveRight"):
		Camera.global_position.x += camera_speed * delta

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
