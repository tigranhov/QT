# QuestTarget (QT)

A World of Warcraft Classic addon that enhances quest targeting and tracking functionality with an intuitive interface and automated features.

## Features

- **Dynamic Target Frame**: Shows a list of nearby quest-related targets and NPCs
- **Auto-Marking System**: Automatically marks quest targets with raid markers
- **Quest Target Scanner**: Continuously scans and updates available quest targets
- **Quest Progress Tracking**: Real-time progress bars for quest objectives
- **Smart Target Cycling**: Keybind support for cycling through available targets
- **Custom Target Support**: Ability to add manual targets for tracking

## Requirements

- World of Warcraft Classic Era or Season of Discovery
- [Questie](https://www.curseforge.com/wow/addons/questie) addon installed and enabled
  - QuestTarget relies on Questie for quest data and objective tracking
  - Minimum required Questie version: Latest version recommended

## Installation

1. Download the latest release
2. Extract the contents to your `World of Warcraft/_classic_era_/Interface/AddOns` directory
3. The folder structure should look like: `Interface/AddOns/QT/`
4. Restart World of Warcraft if it's running

## Usage

The addon automatically activates when you log in. The target frame can be dragged to your preferred position on the screen.

### Main Features

- **Target Frame**: Shows quest targets and turn-in NPCs with progress tracking
- **Auto-Marking**: Automatically marks quest targets (Skull) and turn-in NPCs (Square)
- **Target Scanner**: Continuously updates available quest targets in the vicinity
- **Target Cycling**: Use the configurable keybind (default: TAB) to cycle through available targets
- **Custom Targets**: Add your own targets for temporary tracking

### Slash Commands

#### Main Commands (`/qt` or `/questtarget`)
- `/qt` - Toggle the target frame
- `/qt show` - Show the target frame
- `/qt hide` - Hide the target frame
- `/qt enable` - Enable the addon
- `/qt disable` - Disable the addon
- `/qt help` - Show all available commands

#### Target Frame Commands (`/qtf`)
- `/qtf` - Toggle the target frame
- `/qtf enable` - Show the target frame
- `/qtf disable` - Hide the target frame
- `/qtf completed` - Toggle showing completed targets
- `/qtf keybind <key>` - Set the next target keybind
- `/qtf list` - List all current targets

#### Quest Objectives Commands (`/qto`)
- `/qto add <name>` - Add a custom target by name
- `/qto add target` - Add your current target as a custom target
- `/qto timeout <minutes>` - Set the timeout for custom targets (default: 20 minutes)
- `/qto clear` - Clear all manual objectives
- `/qto print` - Show current manual objectives
- `/qto data <unit name>` - Show detailed unit data

#### Marker Manager Commands (`/qtm`)
- `/qtm` - Toggle auto-marking
- `/qtm enable` - Enable auto-marking
- `/qtm disable` - Disable auto-marking
- `/qtm clear` - Clear all raid markers
- `/qtm config` - Open marker configuration
- `/qtmi` - Toggle party restrictions for markers

## Configuration

The addon can be configured through:
1. In-game slash commands
2. Draggable frames for positioning
3. Marker configuration panel (`/qtm config`)
4. Custom target timeout settings (`/qto timeout`)

## Features in Detail

### Target Frame
- Shows quest targets and turn-in NPCs in a compact list
- Automatically updates based on proximity and quest status
- Progress tracking for incomplete objectives
- Color coding for different target types:
  - Green: Quest turn-in NPCs
  - White: Regular quest targets
  - Yellow: Manual/custom targets

### Auto-Marking System
- Automatically marks quest targets with raid markers
- Turn-in NPCs: Square (6)
- Regular targets: Skull (8)
- Configurable party restrictions

### Quest Target Scanner
- Continuously scans the area for quest-related targets
- Updates target list in real-time as you move
- Supports both quest objectives and custom targets
- Custom targets automatically expire after a configurable timeout (default: 20 minutes)
- Manage custom targets with various `/qto` commands

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Thanks to the WoW Classic community for feedback and suggestions
- Special thanks to all contributors and testers

## Support

For support, please:
1. Check the `/qt help` command for available options
2. Submit an issue on the project repository
3. Contact the addon author in-game 