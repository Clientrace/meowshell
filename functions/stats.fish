function stats
  set repo_name $(git rev-parse --show-toplevel)
  set repo_name (basename $repo_name)
  set repo_name (title_case $repo_name)

  set contribtext ""
  set git_branch_name (git rev-parse --abbrev-ref HEAD)

  if [ -d .git ] || git rev-parse --git-dir > /dev/null 2>&1
    set contrib 0
    set contrib $(git rev-list HEAD --author="Clarence" --count)
    set contribtext "Contrib: $contrib"
  end


  echo "ฅ՞•ﻌ•՞ฅ :" $repo_name
  echo "==>" "branch: " $git_branch_name
  echo "==>" $contribtext



end
