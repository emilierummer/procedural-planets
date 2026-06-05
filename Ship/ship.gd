extends Node2D

var travel_speed: float = 100.0


func _ready() -> void:
    # Ensure ship starts at the correct position (if currently traveling, it will be updated in _process)
    if not SaveData.is_traveling:
        global_position = SaveData.travel_destination_position


## Handle ship movement during travel
func _process(_delta):
    if SaveData.is_traveling:
        var travel_fraction = _calculate_travel_fraction()
        if travel_fraction >= 1.0:
            # Arrived at destination
            global_position = SaveData.travel_destination_position
            SaveData.is_traveling = false
            SaveData.save()
            print("Arrived at destination.")
            rotation = 0.0 # Reset rotation on arrival
        else:
            # Update position based on travel progress
            global_position = SaveData.travel_start_position.lerp(SaveData.travel_destination_position, travel_fraction)
            _rotate_towards_target(SaveData.travel_destination_position)


## Calculate the fraction of the travel completed based on time and speed
func _calculate_travel_fraction() -> float:
    var travel_progress = (Time.get_unix_time_from_system() - SaveData.travel_departure_time) * travel_speed
    var total_distance = SaveData.travel_start_position.distance_to(SaveData.travel_destination_position)
    return travel_progress / total_distance


## Rotate the ship to face the target position
func _rotate_towards_target(target_position: Vector2):
    var to_target: Vector2 = target_position - global_position
    if to_target.length() > 0.0:
        var dir: Vector2 = to_target.normalized()
        # Ship sprite points up; align its up vector to the travel direction.
        rotation = dir.angle() + PI/2