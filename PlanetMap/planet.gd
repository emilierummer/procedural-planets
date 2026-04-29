class_name Planet extends Area2D

signal planet_clicked(planet)


func _input_event(_viewport, event, _shape_idx):
    if event.is_pressed():
        emit_signal("planet_clicked", self)