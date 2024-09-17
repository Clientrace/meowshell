function fish_greeting
  set me (whoami)
  set meow "Meow Shell"
  set meow (set_color green) $meow
  set normal (set_color normal)
  set dir (pwd)
  set dt  (date +%H:%M)
  set last_command $(history | head -2)
  set last_command (printf '%.*s' 40 "$last_command")
  set last_
  set contribtext ""
  if [ -d .git ] || git rev-parse --git-dir > /dev/null 2>&1
    set contrib 0
    set contrib $(git rev-list HEAD --author="Clarence" --count)
    set contribtext "Contrib: $contrib"
  end


  echo -e "Welcome to" $meow $normal "(Fish Shell)!"
  echo -n "
⠀⢀⣤⣶⣶⣶⣆⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣒⣒⣢⣀⠀⠀⠀⠀
⢠⣿⣿⣿⣿⣍⣿⣿⡌⡆⠀⠀⠀⠀⠀⠀⠀⢠⣾⣿⣟⣻⡎⠻⡧⠀⠀⠀  ฅ՞•ﻌ•՞ฅ
⠀⢿⣟⣿⣿⣿⣿⠇⢹⣸⠀⠀⠀⠀⠀⠀⠀⠸⣿⣿⣿⣿⡇⠀⣷⠀⠀⠀  /M e o w  S h e l l/
⠀⠈⠻⣿⠿⠚⠋⠈⠙⠉⢀⢀⣠⣴⣄⣀⣀⠀⠈⠛⠿⣟⣀⡠⠃⠀⠀⠀  User    : $me
⠀⠀⠀⠀⡀⠀⠀⠀⠀⠀⠙⢾⣥⠀⠀⠀⠙⡆⠀⠀⠀⢀⠀⢀⠀⠀⠀⠀  Dir     : $dir
⠀⠀⡠⡪⢀⠔⠠⠂⠀⠀⠀⠀⠹⣷⣤⡶⠋⠁⠀⠊⠔⠡⠐⡁⠀⠀⠀⠀  Time    : $dt
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢂⣷⣯⡡⢀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀  Tail    : $last_command
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡰⠛⠉⠀⠀⠙⠳⡅⠀⠀⠁⡀⠀⠀⠀⠀⠀⠀  $contribtext
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠀⠀⠀⠀⠁⠄⠀⠀⠀⠀
"


end


