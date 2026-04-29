extends VBoxContainer

signal start_travel(destination: Planet)

var current_planet: Planet = null

@onready var PlanetNameLabel:Label = $PlanetNameLabel


func _on_cancel_button_pressed():
    self.hide()


func _on_travel_button_pressed():
    emit_signal("start_travel", current_planet)


func update_planet_info(planet: Planet):
    current_planet = planet
    PlanetNameLabel.text = "Planet: " + planet.name
    self.show()