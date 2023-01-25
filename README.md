# Roblox LSP Module Intellisense
Adds ```---@module path.to.file``` to all instances of a specific pattern.
This provides intellisense for modules that would otherwise not be recognized by RBX-LSP.

## Examples:
```lua
-- Require by name
-- ()local%s+[%w_]+%s=%srequire%("+([%w_]+)"%)
local Console = require("Console")

-- Knit Service
-- ()local%s+[%w_]+%s=%sKnit.GetService%("+([%w_]+)"%)'
local MyService = Knit.GetService("MyService")
```

## Installation:
1. Save this repository root folder and configure your editor's runtime plugin (`robloxLsp.runtime.plugin`) to `YOUR_PATH_HERE/plugin.lua`.