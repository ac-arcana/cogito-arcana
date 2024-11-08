This will not work with 'vanilla' Godot, you need SteamGodot: https://godotsteam.com/
There are multiple versions. This branch is using the Peer-to-Peer version.
This replaces the P2P networking system in Godot with Steam's P2P Framework.

The release used for development of this branch is found here: https://github.com/GodotSteam/GodotSteam/releases/tag/v4.10-mp

Make sure you set your SteamAppID in Steam.gd

To get started:
1. Run project from the main scene - you should get two instances as this is useful for testing functionality, and will need to control them separately.
2. Start a new game in one window.
3. Open the pause menu 
4. Use the new multiplayer menu. To test immediately use the LAN menu and click host, then follow the same steps in the other window but click Join.
