local python_proc = nil
local is_notifier_added = false

-- Function to execute a system command with arguments
function execute_command(command, ...)
    local args = {...}
    local commandString = command

    -- Append arguments to the command string
    for _, arg in ipairs(args) do
        commandString = commandString .. " \"" .. tostring(arg) .. "\""
    end

    -- Execute the command and return the process handle
    return io.popen(commandString, "r")
end

-- Function to start the Python script
function start_python_script(output_path, numitems, sample_length)
    -- Build and execute the command
    python_proc = execute_command("python3 yt-downloader.py", output_path, "--num_videos", numitems, "--sample_length", sample_length)

    -- Check for Python script output periodically
    if not is_notifier_added then
        renoise.tool().app_idle_observable:add_notifier(check_python_output)
        is_notifier_added = true
    end
end

-- Function to check for output from the Python script
function check_python_output()
    if not python_proc then 
        return 
    end
    local output = python_proc:read("*l")  -- Read line by line  
    if output then
        update_gui_with_output(output)  -- Update GUI with the output
    end
end


-- Function to stop the Python script and clean up
function stop_python_script()
  if python_proc then
    python_proc:close()
    python_proc = nil
    
    if is_notifier_added then
     -- Remove the notifier
      renoise.tool().app_idle_observable:remove_notifier(check_python_output)
      is_notifier_added = false
    end
  end
end

