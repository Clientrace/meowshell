function diffrev -d "Review local git diff using cursor-agent"
    # Parse arguments
    set -l diff_args
    set -l use_stdin false
    
    # Process command line arguments
    for arg in $argv
        switch $arg
            case --stdin
                set use_stdin true
            case --help -h
                echo "Usage: diffrev [git-diff-options] [--stdin]"
                echo ""
                echo "Options:"
                echo "  --stdin          Use stdin input method for cursor-agent"
                echo "  --help, -h       Show this help message"
                echo ""
                echo "Examples:"
                echo "  diffrev                    # Review unstaged changes"
                echo "  diffrev --cached           # Review staged changes"
                echo "  diffrev HEAD~1             # Review changes from last commit"
                echo "  diffrev --stdin            # Use stdin method for cursor-agent"
                return 0
            case '*'
                set -a diff_args $arg
        end
    end
    
    # Generate temp file with unique name
    set -l temp_diff "/tmp/diffrev_"(date +%s)"_"(random)".diff"
    
    # Generate git diff
    echo "Generating diff..."
    if test (count $diff_args) -gt 0
        git diff $diff_args > "$temp_diff"
    else
        git diff > "$temp_diff"
    end
    
    # Check if diff file was created and has content
    if not test -f "$temp_diff"
        echo "Error: Failed to create diff file" >&2
        return 1
    end
    
    if test (wc -l < "$temp_diff") -eq 0
        echo "No changes found in diff"
        rm "$temp_diff"
        return 0
    end
    
    echo "Reviewing diff with cursor-agent..."
    
    # Use cursor-agent to review the diff
    if test "$use_stdin" = true
        # Method 1: Use stdin
        if cursor-agent diff-review < "$temp_diff"
            echo "Diff review completed successfully"
        else
            echo "Error: cursor-agent diff review failed" >&2
            rm "$temp_diff"
            return 1
        end
    else
        # Method 2: Use --diff-file flag
        if cursor-agent diff-review --diff-file "$temp_diff"
            echo "Diff review completed successfully"
        else
            echo "Error: cursor-agent diff review failed" >&2
            rm "$temp_diff"
            return 1
        end
    end
    
    # Cleanup
    rm "$temp_diff"
    echo "Cleanup completed"
end
