extends Camera3D
## Make the camera current or disables it based on authority

func _ready():
	current = is_multiplayer_authority()
