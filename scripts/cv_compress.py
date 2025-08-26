#!/usr/bin/env python3
"""
Video Speed and Quality Processor
A script to double the speed of video files and reduce quality to 720p.
Processes all video files in a specified folder.
"""

import cv2
import os
import glob
import argparse
import sys
from pathlib import Path


def get_video_files(folder_path):
    """Get all video files from the specified folder."""
    video_extensions = ['*.mp4', '*.avi', '*.mov', '*.mkv', '*.wmv', '*.flv', '*.webm', '*.m4v']
    video_files = []
    
    for extension in video_extensions:
        pattern = os.path.join(folder_path, extension)
        video_files.extend(glob.glob(pattern, recursive=False))
        # Also check for uppercase extensions
        pattern_upper = os.path.join(folder_path, extension.upper())
        video_files.extend(glob.glob(pattern_upper, recursive=False))
    
    return video_files


def calculate_720p_dimensions(original_width, original_height):
    """Calculate dimensions to maintain aspect ratio with 720p height."""
    target_height = 720
    aspect_ratio = original_width / original_height
    target_width = int(target_height * aspect_ratio)
    
    # Ensure width is even (required for some codecs)
    if target_width % 2 != 0:
        target_width += 1
    
    return target_width, target_height


def process_video(input_path, output_folder=None):
    """Process a single video: double speed and reduce to 720p."""
    print(f"Processing: {input_path}")
    
    # Open video capture
    cap = cv2.VideoCapture(input_path)
    if not cap.isOpened():
        print(f"Error: Could not open video {input_path}")
        return False
    
    # Get video properties
    fps = cap.get(cv2.CAP_PROP_FPS)
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    
    print(f"Original: {width}x{height} at {fps:.2f} FPS, {total_frames} frames")
    
    # Calculate new dimensions for 720p
    new_width, new_height = calculate_720p_dimensions(width, height)
    
    # Double the FPS for 2x speed
    new_fps = fps * 2
    
    # Prepare output path
    input_filename = Path(input_path).stem
    input_extension = Path(input_path).suffix
    if output_folder:
        os.makedirs(output_folder, exist_ok=True)
        output_path = os.path.join(output_folder, f"{input_filename}_2x_720p{input_extension}")
    else:
        output_dir = os.path.dirname(input_path)
        output_path = os.path.join(output_dir, f"{input_filename}_2x_720p{input_extension}")
    
    # Set up video writer
    fourcc = cv2.VideoWriter.fourcc(*'mp4v')  # Alternative syntax for better compatibility
    out = cv2.VideoWriter(output_path, fourcc, new_fps, (new_width, new_height))
    
    if not out.isOpened():
        print(f"Error: Could not create output video {output_path}")
        cap.release()
        return False
    
    print(f"Output: {new_width}x{new_height} at {new_fps:.2f} FPS")
    print(f"Saving to: {output_path}")
    
    # Process frames
    frame_count = 0
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        
        # Resize frame to 720p
        resized_frame = cv2.resize(frame, (new_width, new_height), interpolation=cv2.INTER_AREA)
        
        # Write frame
        out.write(resized_frame)
        
        frame_count += 1
        if frame_count % 100 == 0:
            progress = (frame_count / total_frames) * 100
            print(f"Progress: {progress:.1f}% ({frame_count}/{total_frames} frames)")
    
    # Release everything
    cap.release()
    out.release()
    
    print(f"✅ Completed: {output_path}")
    return True


def main():
    parser = argparse.ArgumentParser(description="Double video speed and reduce quality to 720p")
    parser.add_argument("folder", help="Folder containing video files to process")
    parser.add_argument("-o", "--output", help="Output folder (default: same as input folder)")
    parser.add_argument("--recursive", "-r", action="store_true", help="Search recursively in subfolders")
    
    args = parser.parse_args()
    
    if not os.path.isdir(args.folder):
        print(f"Error: '{args.folder}' is not a valid directory")
        sys.exit(1)
    
    # Find video files
    if args.recursive:
        video_files = []
        for root, dirs, files in os.walk(args.folder):
            for extension in ['mp4', 'avi', 'mov', 'mkv', 'wmv', 'flv', 'webm', 'm4v']:
                pattern = os.path.join(root, f"*.{extension}")
                video_files.extend(glob.glob(pattern))
                pattern_upper = os.path.join(root, f"*.{extension.upper()}")
                video_files.extend(glob.glob(pattern_upper))
    else:
        video_files = get_video_files(args.folder)
    
    if not video_files:
        print(f"No video files found in '{args.folder}'")
        sys.exit(1)
    
    print(f"Found {len(video_files)} video file(s) to process:")
    for video_file in video_files:
        print(f"  - {video_file}")
    
    print("\nStarting processing...")
    
    # Process each video
    success_count = 0
    for video_file in video_files:
        try:
            if process_video(video_file, args.output):
                success_count += 1
            print("-" * 50)
        except Exception as e:
            print(f"Error processing {video_file}: {str(e)}")
            print("-" * 50)
    
    print(f"\n🎉 Processing complete! Successfully processed {success_count}/{len(video_files)} videos.")


if __name__ == "__main__":
    main()