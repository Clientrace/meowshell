function neat -d "Organize files in current directory by type with timestamp naming"
    set -l current_dir (pwd)
    
    # Create directories if they don't exist
    if not test -d "_IMG"
        mkdir "_IMG"
    end
    if not test -d "_MEDIA"
        mkdir "_MEDIA"
    end
    
    # Define file type arrays
    set -l image_exts jpg jpeg png gif bmp tiff webp svg ico raw
    set -l video_exts mp4 avi mkv mov wmv flv webm m4v 3gp mpg mpeg
    set -l audio_exts mp3 wav flac aac ogg m4a wma opus
    
    # Process each file in current directory
    for file in *
        # Skip directories and hidden files
        if test -d "$file" -o (string sub -s 1 -l 1 "$file") = "."
            continue
        end
        
        # Skip if file starts with underscore (our organized folders)
        if string match -q "_*" "$file"
            continue
        end
        
        # Get file extension (lowercase)
        set -l ext (string lower (path extension "$file" | string sub -s 2))
        set -l basename (path basename "$file" ".$ext")
        
        # Get file modification time and format as YYYY-MM-DD
        set -l timestamp (date -r "$file" "+%Y-%m-%d")
        
        # Determine file type and destination
        set -l type_prefix ""
        set -l dest_dir ""
        
        if contains "$ext" $image_exts
            set type_prefix "IMG"
            set dest_dir "_IMG"
        else if contains "$ext" $video_exts
            set type_prefix "VIDEO"
            set dest_dir "_MEDIA"
        else if contains "$ext" $audio_exts
            set type_prefix "AUDIO"
            set dest_dir "_MEDIA"
        else
            set type_prefix "TMP"
            set dest_dir "."
        end
        
        # Create new filename
        if test "$ext" != ""
            set -l new_name "$type_prefix"_"$timestamp"."$ext"
        else
            set -l new_name "$type_prefix"_"$timestamp"
        end
        
        # Handle filename conflicts by adding counter
        set -l counter 1
        set -l final_name "$new_name"
        while test -e "$dest_dir/$final_name"
            if test "$ext" != ""
                set final_name "$type_prefix"_"$timestamp"_"$counter"."$ext"
            else
                set final_name "$type_prefix"_"$timestamp"_"$counter"
            end
            set counter (math $counter + 1)
        end
        
        # Move and rename the file
        mv "$file" "$dest_dir/$final_name"
        echo "Moved: $file → $dest_dir/$final_name"
    end
    
    echo "File organization complete!"
end