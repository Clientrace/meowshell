
function fish_prompt --description 'Write out the prompt'
    set -l last_pipestatus $pipestatus
    set -lx __fish_last_status $status # Export for __fish_print_pipestatus.
    set -l normal (set_color normal)
    set -q fish_color_status
    or set -g fish_color_status red

    # Color the prompt differently when we're root
    set -l color_cwd $fish_color_cwd
    set -l suffix '~>'
    if functions -q fish_is_root_user; and fish_is_root_user
        if set -q fish_color_cwd_root
            set color_cwd $fish_color_cwd_root
        end
        set suffix '#'
    end

    # Write pipestatus
    # If the status was carried over (if no command is issued or if `set` leaves the status untouched), don't bold it.
    set -l bold_flag --bold
    set -q __fish_prompt_status_generation; or set -g __fish_prompt_status_generation $status_generation
    if test $__fish_prompt_status_generation = $status_generation
        set bold_flag
    end
    set __fish_prompt_status_generation $status_generation
    set -l status_color (set_color $fish_color_status)
    set -l statusb_color (set_color $bold_flag $fish_color_status)
    set -l prompt_status (__fish_print_pipestatus "[" "]" "|" "$status_color" "$statusb_color" $last_pipestatus)

    # Default Prompt Appearance
    # echo -n -s (prompt_login)' ' (set_color $color_cwd) (prompt_pwd) $normal (fish_vcs_prompt) $normal " "$prompt_status $suffix " "
    # echo -n -s (prompt_login)' ' (set_color $color_cwd) (prompt_pwd) $normal (fish_vcs_prompt) $normal " "$prompt_status $suffix " "

    # Modifications
    # ======================

    set last_command $(history | head -1)
    set emote (set_color yellow) "[😺]"

    if string match -q -- "git push*" $last_command
        if test -n "$prompt_status"
            set emote $status_color $statusb_color "[😿]"
        else
            set emote (set_color green) "[🚀]"
        end
    else
        if test -n "$prompt_status"
            set emote $status_color $statusb_color "[😿]"
        end
    end
 

    set MAX_BRANCH_NAME 8

    set -l num 1
    set -l n_vcs (fish_vcs_prompt) 
    and set n_vcs (string replace -a ' ' '' $n_vcs)
    and set n_vcs (printf '<%.*s>' $MAX_BRANCH_NAME "$n_vcs")
    and set n_vcs (string replace -a '(' '' $n_vcs)
    and set n_vcs (string replace -a ')' '' $n_vcs)
    set n_vcs $normal $n_vcs

    set duration (math $CMD_DURATION / 1000)

    echo -n -s (set_color 62A) "▲" $duration": " (set_color green) (prompt_pwd) $n_vcs $emote (set_color yellow) $suffix " "

    # set count (math $count + 1)
    # ======================

end


