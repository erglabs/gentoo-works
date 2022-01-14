function separator()
{
    echo '##################################################'
    return 0
}

function separator_n()
{
    echo ' '
    separator
    echo ' '
    return 0
}

function blankline()
{
    echo ' '
}


function ynquestion()
{
    # $1 query
    # (posix querry, 0=ok!)
    # r=>1 on false
    # r=>0 on true

    echo "$1"

    while true ; do
        # version echoing choice:
        # read -s -n 1 -rep "$(_:gclred) [Y]es/[N]o $(_:gcreset)" -p $'\n'
        read -s -n 1 -rep "[Y]es/[N]o" -p $'\n'
        if [[ ${REPLY} =~ ^[Yy]$ ]] ; then
            return 0
            break
        fi
  if [[ ${REPLY} =~ ^[Nn]$ ]] ; then
            return 1
            break
            fi
  echo "invalid answer, i need : N, n, Y or y"
    done
}
