class_name CogitoVehicleSynchronizer
extends Node

@export var level_spawner : MultiplayerLevelSpawner

var vehicle_array

# This is WIP as I wanted to update to the latest version of Cogito. 
# This sychronizer is not fully functional
# This is used to prevent a crash as the vehicles keep a reference to the player
func _ready():
	level_spawner.level_loaded.connect(_on_multiplayer_level_spawner_level_loaded)

func _on_multiplayer_level_spawner_level_loaded():
	vehicle_array = level_spawner.find_children("", "CogitoVehicle", true, false)
	for vehicle in vehicle_array:
		#Temporarily disable physics for vehicles to prevent crash
		vehicle.set_physics_process(false)
