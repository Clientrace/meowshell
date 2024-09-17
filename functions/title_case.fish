function title_case
    set input $argv[1]
    echo $input | sed 's/\(.\)/ \1/g'
end
