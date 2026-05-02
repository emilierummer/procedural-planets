extends Control

signal start_travel(destination: Planet)
signal close_planet_info()

var current_planet: Planet = null

@onready var PlanetNameLabel: Label = $VBoxContainer/PlanetNameLabel
@onready var LandCoverLabel: Label = $VBoxContainer/LandCoverLabel
@onready var OceanDepthLabel: Label = $VBoxContainer/OceanDepthLabel
@onready var TerrainLabel: Label = $VBoxContainer/TerrainLabel
@onready var TemperatureLabel: Label = $VBoxContainer/TemperatureLabel
@onready var GravityLabel: Label = $VBoxContainer/GravityLabel


func _on_cancel_button_pressed():
	self.hide()
	close_planet_info.emit()


func _on_travel_button_pressed():
	start_travel.emit(current_planet)


func update_planet_info(planet: Planet):
	current_planet = planet
	PlanetNameLabel.text = planet.name
	LandCoverLabel.text = "Land Cover: " + str(round(planet.land_cover * 100.0)) + "%"
	OceanDepthLabel.text = "Ocean Depth: " + str(round(planet.ocean_average_depth * 100.0)) + "%"
	TerrainLabel.text = "Terrain: " + Planet.get_terrain_label(planet.elevation_frequency, planet.elevation_strength, planet.elevation_contrast)
	TemperatureLabel.text = "Temperature: %s (%d°F)" % [Planet.get_temperature_label(planet.temperature), round(planet.temperature)]
	GravityLabel.text = "Gravity: " + str(round(planet.planet_gravity * 100.0) / 100.0) + " Gs"

	self.show()
