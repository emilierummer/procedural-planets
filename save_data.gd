extends Node

const SAVE_FILE_PATH = "user://save_data.cfg"

## Travel: Is the ship currently traveling?
var is_traveling: bool = false
## Travel: Start position
var travel_start_position: Vector2 = Vector2.ZERO
## Travel: Destination position
var travel_destination_position: Vector2 = Vector2.ZERO
## Travel: Destination planet name
var travel_destination_name: String = ""
## Travel: Departure time
var travel_departure_time: float = 0.0


## Load data on start
func _ready() -> void:
	self.load()


## Save data to file
func save() -> void:
	var config: ConfigFile = ConfigFile.new()

	var save_section = "travel"
	config.set_value(save_section, "is_traveling", is_traveling)
	config.set_value(save_section, "travel_start_position", travel_start_position)
	config.set_value(save_section, "travel_destination_position", travel_destination_position)
	config.set_value(save_section, "travel_destination_name", travel_destination_name)
	config.set_value(save_section, "travel_departure_time", travel_departure_time)

	var err: int = config.save(SAVE_FILE_PATH)
	if err != OK:
		print("Error saving data: Could not write ConfigFile. Error code: %s" % err)


## Load data from file
func load() -> void:
	var config: ConfigFile = ConfigFile.new()
	var err: int = config.load(SAVE_FILE_PATH)
	if err == OK:
		var save_section = "travel"
		is_traveling = config.get_value(save_section, "is_traveling", false)
		travel_start_position = config.get_value(save_section, "travel_start_position", Vector2.ZERO) as Vector2
		travel_destination_position = config.get_value(save_section, "travel_destination_position", Vector2.ZERO) as Vector2
		travel_destination_name = config.get_value(save_section, "travel_destination_name", "") as String
		travel_departure_time = config.get_value(save_section, "travel_departure_time", 0.0)
	else:
		print("No save data found, starting with default values.")
