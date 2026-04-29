extends VBoxContainer

signal start_travel(destination: Planet)
signal close_planet_info()

var current_planet: Planet = null

@onready var PlanetNameLabel:Label = $PlanetNameLabel


func _on_cancel_button_pressed():
    self.hide()
    close_planet_info.emit()


func _on_travel_button_pressed():
    start_travel.emit(current_planet)


func update_planet_info(planet: Planet):
    current_planet = planet
    PlanetNameLabel.text = "Planet: " + planet.name
    self.show()