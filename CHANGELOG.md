# Changelog

## [1.1.0] - 2024-01-24

### Added
- Enhanced slash command functionality with improved documentation
- Enhanced unit filtering system in MarkerManager and QuestObjectives

### Changed
- Streamlined unit filtering in MarkerManager and QuestObjectives
- Updated Marker Manager commands and documentation
- Improved marker configuration system

### Fixed
- Removed redundant marker configuration panel mention from README.md

## [1.0.1] - 2024-01-24

### Fixed
- Fixed issue with target marking not working in certain scenarios
- Improved marker handling when target already has a different marker
- Added small delay to ensure reliable marker setting

## [1.0.0] - 2024-01-24

### Features
- Dynamic target frame with quest objective tracking
- Auto-marking system for quest targets and turn-in NPCs
- Quest target scanner with real-time updates
- Custom target support with configurable timeouts
- Smart target cycling with keybind support
- Progress tracking for quest objectives
- Color-coded target types (turn-in NPCs, regular targets, custom targets)

### Commands
- Main addon control (`/qt`)
- Target frame management (`/qtf`)
- Quest objectives and custom targets (`/qto`)
- Marker management (`/qtm`)
- Party restrictions toggle (`/qtmi`)

### Technical
- Integration with Questie for quest data
- Efficient unit caching system
- Real-time target scanning
- Custom target timeout system (default: 20 minutes)
- Secure action button implementation for target cycling
- Saved variables for settings persistence

### Requirements
- World of Warcraft Classic Era or Season of Discovery
- Questie addon (latest version recommended) 