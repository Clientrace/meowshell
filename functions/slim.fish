function slim --description 'Compress videos: double speed and reduce to 720p'
    # Get the directory where this function is located
    set script_dir (dirname (status -f))
    set cv_compress_script "$script_dir/../scripts/cv_compress.py"
    
    # Check if no arguments provided
    if test (count $argv) -eq 0
        echo "Usage: slim <folder> [options]"
        echo ""
        echo "Compress videos by doubling speed and reducing quality to 720p"
        echo ""
        echo "Arguments:"
        echo "  folder              Folder containing video files to process"
        echo ""
        echo "Options:"
        echo "  -o, --output DIR    Output folder (default: same as input folder)"
        echo "  -r, --recursive     Search recursively in subfolders"
        echo "  -h, --help          Show this help message"
        echo ""
        echo "Examples:"
        echo "  slim ~/Videos                    # Process videos in ~/Videos"
        echo "  slim ~/Videos -o ~/Compressed    # Save to ~/Compressed folder"
        echo "  slim ~/Videos -r                 # Process recursively"
        return 1
    end
    
    # Check if help is requested
    if contains -- -h $argv; or contains -- --help $argv
        slim
        return 0
    end
    
    # Check if the Python script exists
    if not test -f "$cv_compress_script"
        echo "Error: cv_compress.py script not found at $cv_compress_script"
        return 1
    end
    
    # Check if python3 is available
    if not command -v python3 > /dev/null
        echo "Error: python3 is not installed or not in PATH"
        return 1
    end
    
    # Check if opencv-python is installed
    if not python3 -c "import cv2" 2>/dev/null
        echo "Error: opencv-python is not installed"
        echo "Install it with: pip3 install opencv-python"
        return 1
    end
    
    # Run the Python script with all provided arguments
    python3 "$cv_compress_script" $argv
end