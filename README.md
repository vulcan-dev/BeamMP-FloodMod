# BeamMP-FloodMod

This is a resource for BeamMP that adds a flood to all sorts of maps (as long as they have an ocean).

## Installation
1. Download the latest release from the [releases page](https://github.com/vulcan-dev/BeamMP-FloodMod/releases)
2. Copy `floodBeamMP.zip` into your `BeamMP-Server/Resources/Client` folder
3. Copy `Flood` into your `BeamMP-Server/Resources/Server` folder

## Commands
- `/flood_start` - Starts the flood
- `/flood_stop` - Stops the flood
- `/flood_reset` - Resets the height and disables the flood
- `/flood_level <level>` - Sets the flood level/height
- `/flood_speed <speed>` - Sets the flood speed (0.001 is default)
- `/flood_decrease <on/off>` - Makes the water level decrease instead of increase
- `/flood_limit <limit_number/off>` - Sets the flood height limit
- `/flood_printSettings` - Prints the current flood settings

## Changes for 1.1.0
- The water now updates on the client with deltatime and exponential decay to make sure it's not jittery and stays in sync. The server still updates it as well. If it goes too far out of sync, it will update instantly.
- The server now sends the water level every second instead of every 25ms. I recommend leaving it at 1 second.
- Remove rain and rain sound functionality. 
- Updated the `modScript` to use the new `setExtensionUnloadMode` function.
- Fixed some issues with decreasing the water level.
- Fixed duplicate timers when calling reset.

## Credits
- [Dudekahedron](https://github.com/StanleyDudek) - Testing and providing a test server