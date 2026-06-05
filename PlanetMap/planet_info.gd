extends Control

signal start_travel(destination: Planet)
signal close_planet_info()

var current_planet: Planet = null

@onready var MainInfoPanel: PanelContainer = %MainInfo
@onready var PlanetNameLabel: Label = %MainInfo/VBoxContainer/PlanetNameLabel
@onready var LandCoverLabel: Label = %MainInfo/VBoxContainer/LandCoverLabel
@onready var OceanDepthLabel: Label = %MainInfo/VBoxContainer/OceanDepthLabel
@onready var TerrainLabel: Label = %MainInfo/VBoxContainer/TerrainLabel
@onready var TemperatureLabel: Label = %MainInfo/VBoxContainer/TemperatureLabel
@onready var GravityLabel: Label = %MainInfo/VBoxContainer/GravityLabel

@onready var ConfirmPanel: PanelContainer = %ConfirmTravel
@onready var DestinationLabel: Label = %ConfirmTravel/VBoxContainer/DestinationLabel
@onready var ConfirmNoButton: Button = %ConfirmNo
@onready var ConfirmYesButton: Button = %ConfirmYes


func _on_cancel_button_pressed():
	self.hide()
	close_planet_info.emit()


func _on_travel_button_pressed():
	if SaveData.is_traveling:
		# If already traveling, show confirmation dialog to cancel current travel
		ConfirmPanel.show()
		DestinationLabel.text = "Ship is currently traveling to %s.\nGo to %s instead?" % [SaveData.travel_destination_name, current_planet.name]
		ConfirmNoButton.text = "No, keep going to %s" % SaveData.travel_destination_name
		ConfirmYesButton.text = "Yes, change course to %s" % current_planet.name
	else:
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


func _on_confirm_yes_pressed():
	ConfirmPanel.hide()
	start_travel.emit(current_planet)


func _on_confirm_no_pressed():
	ConfirmPanel.hide()
