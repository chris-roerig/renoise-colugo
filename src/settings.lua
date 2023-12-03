require "renoise.http"

-- Define a document for preferences
local preferences = renoise.Document.create("ScriptingToolPreferences") {
    output_path = "",
    num_videos = 10,
    sample_length = 1000  
}

-- Function to load preferences
function load_preferences()
    renoise.tool().preferences = preferences
    preferences:load_from("userpreferences.xml")
    return preferences
end

-- Function to save preferences
function save_preferences(key, value)
    if preferences[key] ~= nil then
        preferences[key].value = value
        preferences:save_as("userpreferences.xml")
    else
        -- Optionally handle the case where the key is not valid
        print("Error: Preference key '" .. key .. "' does not exist.")
    end
end

