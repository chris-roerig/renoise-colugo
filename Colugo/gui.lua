require "run_python"
require "settings" 

-- Global references to the GUI elements
local text_input
local feedback_textbox
local toggle_button
local output_path
local num_videos_valuebox
local sample_length_valuebox
local is_script_running = false

local preferences = load_preferences()

function update_gui_with_output(output)
    if feedback_textbox then
        feedback_textbox.text = feedback_textbox.text .. "\n" .. output
        -- Check if the output contains the completion message
        if output:find("Done!") then
            -- Perform actions after the script is done
            is_script_running = false
            toggle_button.text = "Start Sampling"
        end   
        feedback_textbox:scroll_to_last_line()
    end
end

local function load_words_file()
    local file = io.open("words.txt", "r")
    if file then
        local content = file:read("*all")
        file:close()
        return content
    else
        return ""
    end
end

local function save_words_file(text)
    local file = io.open("words.txt", "w")
    if file then
        file:write(text)
        file:close()
    end
end

local function choose_directory()
    return renoise.app():prompt_for_path("Select Output Folder")
end

function cancel_python_script()
  local file = io.open("cancel.flag", "w")
  file:close()
  stop_python_script()
end

-- Update the start/stop script function
local function toggle_script(vb)
    if is_script_running then
        -- Stop the script
        cancel_python_script()
        is_script_running = false
        local output = vb.views.feedback_textbox.text
        vb.views.toggle_button.text = "Start Sampling"
        vb.views.feedback_textbox.text = output .. "\nScript stopped\n=============\n"
         feedback_textbox:scroll_to_last_line()        
    else
        -- Start the script
        if not text_input.text or text_input.text == "" then
            vb.views.feedback_textbox.text = "Error: No words provided. Please enter some words."
            return
        end

        if not output_path or output_path == "" then
            vb.views.feedback_textbox.text = "Error: No output directory selected. Please select an output directory."
            return
        end

        save_words_file(text_input.text)
        vb.views.feedback_textbox.text = "Words saved and Output path set."
        start_python_script(output_path, tostring(num_videos_valuebox.value), tostring(sample_length_valuebox.value))
        vb.views.toggle_button.text = "Stop Sampling"
        is_script_running = true
    end
end

-- Create and show the dialog
function show_dialog()
  local vb = renoise.ViewBuilder()
  
  -- Function to handle the directory selection
  local function on_choose_dir_button_clicked()
      local chosen_dir = choose_directory()
      if chosen_dir and chosen_dir ~= "" then
          output_path = chosen_dir
          vb.views.output_path_text.text = chosen_dir
          save_preferences("output_path", chosen_dir)
      end
  end
    
  -- Dialog content
  local content = vb:column {
      margin = 10,
      spacing = 5,
      vb:multiline_textfield {
          id = "text_input",
          width = 400,
          height = 200,
          text = load_words_file()
      },
      vb:row {
          spacing = 5,
          vb:text {
              text = "Sample Length (milliseconds):",
              width = 150
          },
          vb:valuebox {
              id = "sample_length",
              min = 500,
              max = 10000,
              value = 1000,
              width = 65,
              notifier = function()
                save_preferences("sample_length", vb.views.sample_length.value)
              end
          },
      },
      vb:row {
          spacing = 5,
          vb:text {
              text = "Number of Videos:",
              width = 150
          },
          vb:valuebox {
              id = "num_videos",
              min = 1,
              max = 100,
              value = 10,
              width = 55,
              notifier = function()
                save_preferences("num_videos", vb.views.num_videos.value)
              end
          },
      },          
      vb:row {
          spacing = 5,
          vb:text {
              id = "output_path_text",
              text = "Select output path (button on the right) --->",
              width = 375
          },
          vb:button {
              text = "...",
              notifier = on_choose_dir_button_clicked
          },
      },
      -- Create a horizontal row for buttons
      vb:row {
          spacing = 5,
          -- Start Sampling Button
          vb:button {
              id = "toggle_button",
              text = "Start Sampling",
              notifier = function()
                toggle_script(vb)
              end
          },
      },      
      vb:multiline_textfield {
          id = "feedback_textbox",
          width = 400,
          height = 100,
          text = "Status will be shown here",
      },
  }
 
  if preferences.output_path.value ~= "" then
    vb.views.output_path_text.text = preferences.output_path.value
    output_path = preferences.output_path.value
  end

  if preferences.num_videos and preferences.num_videos.value ~= "" then
      vb.views.num_videos.value = tonumber(preferences.num_videos.value)
  else
      vb.views.num_videos.value = 10
  end
  
  if preferences.sample_length and preferences.sample_length.value ~= "" then
      vb.views.sample_length.value = tonumber(preferences.sample_length.value)
  else
      vb.views.sample_length.value = 1000
  end


  -- Retrieve references to the GUI elements
  text_input = vb.views.text_input
  num_videos_valuebox = vb.views.num_videos
  sample_length_valuebox = vb.views.sample_length
  feedback_textbox = vb.views.feedback_textbox
  toggle_button = vb.views.toggle_button


  -- Show the dialog
  renoise.app():show_custom_dialog(TOOL_NAME.." "..TOOL_VERSION.." by Jugwine", content)
end
