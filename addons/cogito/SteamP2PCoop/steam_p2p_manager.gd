extends Node
## Setup Steam Environment, setup callbacks

## Set this to whatever your SteamAppID is. 480 will work fine for testing.
@export var SteamAppID : int = 480

func _ready():
	OS.set_environment("SteamAppID", str(SteamAppID))
	OS.set_environment("SteamGameID", str(SteamAppID))
	
	var initialize_response: Dictionary = Steam.steamInitEx()
	print("Did Steam initialize?: %s " % initialize_response)
	
	## if steam did not initialize properly then shut down
	if initialize_response['status'] > 0:
		printerr("Failed to initialize Steam, shutting down: %s" % initialize_response)
		get_tree().quit()


func _process(_delta : float):
	Steam.run_callbacks()
