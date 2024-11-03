# BeamMP-FloodMod

This is a resource for BeamMP that adds a flood to all sorts of maps (as long as they have an ocean).

## Installation
1. Download the latest release from the [releases page](https://github.com/vulcan-dev/BeamMP-FloodMod/releases)
2. Copy `floodBeamMP.zip` into your `BeamMP-Server/Resources/Client` folder
3. Copy `Flood` into your `BeamMP-Server/Resources/Server` folder

## Commands
### v1.1.0 Preview
- `/flood_start` - Starts the flood
- `/flood_stop` - Stops the flood
- `/flood_reset` - Resets the height and disables the flood
- `/flood_resetAt` - TODO
- `/flood_level <level:integer>` - Sets the flood level/height
- `/flood_speed <speed:float>` - Sets the flood speed (0.001 is default)
- `/flood_decrease <enabled:boolean>` - Makes the water level decrease instead of increase
- `/flood_limit <limit:number>` - Sets the flood height limit
- `/flood_printSettings` - Prints the current flood settings

### v1.0.1
- `/flood_start` - Starts the flood
- `/flood_stop` - Stops the flood
- `/flood_reset` - Resets the height and disables the flood
- `/flood_setLevel <level>` - Sets the flood level/height
- `/flood_setSpeed <speed>` - Sets the flood speed (0.001 is default)
- `/flood_setDecrease <decrease>` - Makes the water level decrease instead of increase
- `/flood_setLimit <limit>` - Sets the flood height limit
- `/flood_setLimitEnabled <enabled>` - Enables or disables the flood height limit
- `/flood_printSettings` - Prints the current flood settings

## Credits
- [Dudekahedron](https://github.com/StanleyDudek) - Testing and providing a test server
