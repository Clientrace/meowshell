function start
    # Define the path to the config file
    set -l config_dir $HOME/.config/fish
    set -l config_file $config_dir/start_config
    
    # Define a default start directory in case the file is newly created
    set -l default_dir "/home/clarence/Dev/meowshell" 
    
    # Initialize the variable as a blank string
    set -l start_directory "" 

    # --- 1. File Setup and Initial Read ---
    if not test -d $config_dir
        mkdir -p $config_dir
    end

    if not test -f $config_file
        # Create file with the default and assign the directory directly
        echo "start_directory=$default_dir" > $config_file
        echo "✅ Config file created: $config_file"
        echo "Using default start directory: $default_dir"
        
        # Assign as a single string
        set start_directory "$default_dir"
    else
        # Read the file contents and extract the directory
        set -l config_lines (cat $config_file)
        
        # --- CRITICAL FIX: Use string split and index 1 to guarantee a single string ---
        # 1. Pipe all config lines.
        # 2. Match the specific line.
        # 3. Replace the key prefix.
        # 4. Trim whitespace.
        # 5. Use string split to turn any remaining spaces/newlines into list items.
        # 6. Take only the FIRST item ([1]) from the resulting list.
        set -l extracted_path (
            echo $config_lines | 
            string match -r '^start_directory=(.*)' | 
            string replace 'start_directory=' '' | 
            string trim | 
            string split \n
        )
        
        # Assign the first (and only valid) item, ensuring it's not a list.
        if test (count $extracted_path) -ge 1
            set start_directory $extracted_path[1]
        end
    end

    # --- 2. Handle --target argument (Saving Logic - Unchanged) ---
    if contains -- --target $argv
        argparse 't/target=' -- $argv
        
        if set -q _flag_target
            set -l new_target $_flag_target

            if test -d $new_target
                # Read existing lines (excluding the target line)
                set -l filtered_lines (string match -r --invert '^start_directory=' (cat $config_file))
                
                # Add the new target line and write the new content back to the file
                set -l new_config_content (printf "%s\n" $filtered_lines "start_directory=$new_target")
                echo $new_config_content > $config_file
                
                echo "✅ New start directory saved to config: $new_target"
                return 0
            else
                echo "❌ Error: Target directory does not exist: $new_target"
                return 1
            end
        end
    end

    # --- 3. Execution Logic ---
    # Quoting is essential here to treat the variable as a single path, even if it contained spaces.
    if test -n "$start_directory"
        # Ensure the configured path is valid
        if test -d "$start_directory"
            echo "➡️ Changing directory to: $start_directory"
            cd "$start_directory"
            
            if functions -q stats
                stats
            else
                echo "ℹ️ Note: 'stats' function not found."
            end
        else
            echo "⚠️ Configured start directory does not exist: **$start_directory**"
            echo "Please run 'start --target /path/to/new/directory' to set a valid one."
        end
    else
        # If the file exists but the key is still missing
        echo "❌ No 'start_directory' setting found in the config file: $config_file"
        echo "Please run 'start --target /path/to/directory' to set it."
    end
end