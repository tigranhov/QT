# QuestTarget Development Guidelines

> **Maintainer Instructions**:
> - This is a living document that must be kept up to date
> - When implementing new patterns or discovering better practices, update this document
> - When finding inconsistencies between code and guidelines, either:
>   1. Update the code to match the guidelines, or
>   2. Update the guidelines if the new pattern is better
> - All significant technical decisions should be documented here

## Cursor Composer Instructions

When working with this codebase, the AI should:
1. Always verify code changes against these guidelines before implementing
2. Update this document when discovering new patterns or better practices
3. Maintain consistent naming, structure, and patterns across all modules
4. Use virtual frames and Show/Hide for enable/disable functionality
5. Implement proper error checking and initialization patterns
6. Follow the documentation standards for files and functions
7. Use consistent debug message formatting
8. Keep module state management consistent (isInitialized, enabled flags)
9. Implement slash commands according to the established pattern
10. Store timing variables on frame objects for clean state management
11. Alert the user when deviating from these guidelines is necessary
12. Suggest improvements to these guidelines when better patterns are found

To apply these instructions in a new composer session, tell the AI to:
"Please adhere to the composer instructions in QT/GUIDELINES.md"

## Code Organization

### Module Structure
- Each module should be in its own file under the appropriate directory (`Core/` or `UI/`)
- Use the standard module template:
```lua
local addonName, ns = ...
ns = ns or {}

local ModuleName = {
    isInitialized = false,
    -- other properties
}

-- Export the module
ns.ModuleName = ModuleName
return ModuleName
```

## Frame Management

### Visual Frames (UI)
- Use Show/Hide directly for visibility management
- Save visibility state in settings if needed
- Implement Toggle function for visibility switching
```lua
function Module:Show()
    self.frame:Show()
    -- Update settings if needed
end

function Module:Hide()
    self.frame:Hide()
    -- Update settings if needed
end

function Module:Toggle()
    if self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end
```

#### Utility Frames
- Use virtual frames (frames without size/position) for non-visual functionality
- Use Enable/Disable pattern with frame visibility for functionality control
- Example use cases: event handling, timers, update loops
```lua
function Module:Enable()
    self.enabled = true
    self.frame:Show()  -- Enables OnUpdate
end

function Module:Disable()
    self.enabled = false
    self.frame:Hide()  -- Stops OnUpdate
end
```

### Update Loops
- Use OnUpdate with throttling for periodic updates
- Store timing variables on the frame itself
```lua
frame.TimeSinceLastUpdate = 0
frame:SetScript("OnUpdate", function(frame, elapsed)
    frame.TimeSinceLastUpdate = frame.TimeSinceLastUpdate + elapsed
    if frame.TimeSinceLastUpdate > UPDATE_FREQUENCY then
        -- Do update
        frame.TimeSinceLastUpdate = 0
    end
end)
```

## Error Handling

### Initialization Checks
- Always check initialization state before operations
- Check dependencies before initializing
```lua
if not self.isInitialized then return end
if not ns.RequiredModule then return end
```

## User Interface

### Slash Commands
- Main addon commands use the pattern: `/qt <command>`
- Module-specific commands use the pattern: `/qt<module> <command>`
- Every module with enable/disable functionality should support:
  - `/qt<module>` or `/qt<module> toggle` - Toggle module
  - `/qt<module> enable` - Enable module
  - `/qt<module> disable` - Disable module
- Example responses:
  ```lua
  print("[QT] ModuleName enabled")
  print("[QT] ModuleName disabled")
  ```

### Debug Messages
- Use consistent format for debug messages:
```lua
print("[QT] Message")  -- Regular messages
print("[QT-Debug] Message")  -- Debug messages
```

## Performance Optimization

### Frame Updates
- Use frame visibility to pause update loops when functionality is disabled
- Implement throttling for frequent updates
- Store last update time on frame itself to maintain clean state

## State Management

### Module State
- Track initialization with `isInitialized`
- Track enabled state with `enabled`
- Use consistent property names across modules

## Documentation

### File Headers
```lua
--[[
    ModuleName Module
    Brief description of module's purpose and functionality.
]]
```

### Function Documentation
```lua
--[[
    Brief description of function
    @param paramName type - description
    @return type - description
]]
```

#### Logic Block Documentation
- Document complex logic blocks with inline comments
- Explain the "why" not just the "what"
- Use clear section separators for different logic stages
- Example:
```lua
-- First stage: Collect and categorize units
-- We separate targets and turn-in NPCs to ensure proper priority handling
for _, unit in ipairs(units) do
    if unit.isTarget then
        -- Regular targets get priority to ensure combat objectives are handled first
        table.insert(targets, unit)
    elseif unit.isTurnInNpc then
        -- Store turn-in NPCs as fallback for when no combat targets exist
        table.insert(turnInNpcs, unit)
    end
end
```

---

This document will be updated as new patterns and standards are established. All new code should follow these guidelines for consistency. 