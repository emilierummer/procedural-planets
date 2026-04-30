class_name Planet extends Area2D

# ============ SHADER PARAMETERS ============ #

var atmosphere_color: Color

var cloud_cover: float # Range 0.0 to 1.0
var cloud_density: float # Range 0.0 to 1.0
var cloud_color: Color

var land_cover: float # Range 0.0 to 1.0
var land_color_low: Color
var land_color_high: Color
var elevation_frequency: float
var elevation_strength: float
var elevation_contrast: float

var ocean_color_deep: Color
var ocean_color_shallow: Color
var ocean_average_depth: float # Range 0.0 to 1.0, where 0.0 is very shallow and 1.0 is very deep
var ocean_depth_variation: float # Range 0.0 to 1.0, where 0.0 is no variation (all ocean the same depth) and 1.0 is high variation (ocean depth varies widely)
var ocean_depth_contrast: float


signal planet_clicked(planet)


func _input_event(_viewport, event, _shape_idx):
    if event.is_pressed():
        emit_signal("planet_clicked", self)