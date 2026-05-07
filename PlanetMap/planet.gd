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

# ============ PLANET PROPERTIES ============ #

var temperature: float # Range -400.0 to 900.0, representing average surface temperature in Fahrenheit
var planet_gravity: float # Range 0.0 to 5.0, where 1.0 is Earth-like gravity, 0.0 is no gravity, and 5.0 is very high gravity

var position_offset: Vector2 # Offset from the planet's grid position, used for visual variation
var planet_size: float # Range 0.5 to 2.0, representing the size of the planet sprite (relative to a 32px base size)

# ============ STATIC CONVERSIONS ============ #

## Get a human-readable temperature label based on the planet's temperature value
static func get_temperature_label(temp: float) -> String:
    if   temp < -200.0: return "Frigid"
    elif temp < -100.0: return "Cold"
    elif temp < 0.0:    return "Cool"
    elif temp < 120.0:  return "Temperate"
    elif temp < 300.0:  return "Warm"
    elif temp < 600.0:  return "Hot"
    else:               return "Scorching"


## Get hue range for planet color based on temperature
## temperature can be a string label or a float value
static func get_temperature_hue_range(temp) -> Array:
    if not temp is String:
        temp = Planet.get_temperature_label(temp)
    
    # Match temperature label to corresponding hue range
    match temp:
        "Frigid":    return [0.50, 0.59] # Cyan-blue
        "Cold":      return [0.42, 0.50] # Cyan
        "Cool":      return [0.33, 0.42] # Cyan-green
        "Temperate": return [0.25, 0.33] # Green
        "Warm":      return [0.17, 0.25] # Yellow-green
        "Hot":       return [0.08, 0.17] # Orange-yellow
        "Scorching": return [0.00, 0.08] # Red-orange
    # Default to full hue range if temperature is invalid
    return [0.00, 1.00] 


## Get a human-readable terrain label based on the planet's elevation
static func get_terrain_label(el_frequency: float, el_strength: float, el_contrast: float) -> String:
    # Once gravity is factored in:
    # el_frequency range: 0.8 to 160
    # el_strength range: 0.0 to 20
    # el_contrast range: 0.16 to 30
    # el_score range: 2.56 to 500 (logarithmic scale)
    var el_score = (el_frequency + max(el_strength, 0.1) * 8.0 + el_contrast * 6.0)

    if   el_score > 250.0: return "Jagged"
    elif el_score > 125.0: return "Mountainous"
    elif el_score > 62.5:  return "Hilly"
    elif el_score > 31.25: return "Rolling"
    else:                  return "Flat"


# ============================================ #

signal planet_clicked(planet)


func _input_event(_viewport, event, _shape_idx):
    if event.is_pressed():
        emit_signal("planet_clicked", self)