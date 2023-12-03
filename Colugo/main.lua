require "gui"

-- Constants
-- Global Constants
TOOL_NAME = "Colugo"
TOOL_VERSION = "1.0.1"
TOOL_AUTHOR = "Jugwine"
TOOL_DESCRIPTION = "A creative sample graber"

-- Main function
function main()
   -- Your code here
end

_tool_registered = nil
if not _tool_registered then

-- Add menu entries
renoise.tool():add_menu_entry {
   name = "Main Menu:Tools:" .. TOOL_NAME,
   invoke = function() show_dialog() end
}

-- Key Binding
renoise.tool():add_keybinding {
   name = "Global:Tools:" .. TOOL_NAME,
   invoke = main
}

-- MIDI Mapping
renoise.tool():add_midi_mapping {
   name = TOOL_NAME .. ":Invoke",
   invoke = main
}

   _tool_registered = true
end

-- Function to be called when a new document is created
local function onNewDocument()
   -- Your code to execute when a new document is created
end

-- Check if the notifier is already added, and if not, add it
if not renoise.tool().app_new_document_observable:has_notifier(onNewDocument) then
   renoise.tool().app_new_document_observable:add_notifier(onNewDocument)
end

