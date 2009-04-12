#!/bin/bash
#
# works on cygwin and OS X 10.4
#
action=$1

#_list() {
#  echo "listing ..."
#}

# now shift the positional parameters to the right, past
# the plug-in action, so that they can be pasted to the
# built-in actions.
#
shift

# handle the usage action
#
[ "$action" = "usage" ] && [[ "$2" == "version" ]] && {
    sed -e 's/^    //' <<EndVersion
      dthls Add-on, version 0.0.0.

        First release: 10-APR-2009
        Author: Dave Hein
        License: GPL, http://www.gnu.org/copyleft/gpl.html
EndVersion
    exit
}

[ "$action" = "usage" ] && [[ "$2" == "short" ]] && {
    sed -e 's/^    //' <<EndUsage
      dthls [-@+Pr] [-m MAX]  [-l LEN] [TERM...] 
EndUsage
  exit
}

[ "$action" = "usage" ] && {
    sed -e 's/^    //' <<EndUsage
      dthls [-@+Pr] [-m MAX]  [-l LEN] [TERM...] 
        Displays all todo's that contain TERM(s) sorted by priority with line
        numbers.  If no TERM specified, lists entire todo.txt.

        Options:
          -@
              Hide context names in list output. Use twice to show context
              names (default).
          -+
              Hide project names in list output. Use twice to show project
              names (default).
          -l  LEN
              Truncates displayed lines at LEN, displaying ellipses
              (...) if line length is longer. -l 0 does not truncate.
              If specified multiple times, the last one wins.
              LEN ignored if less than or equal to 10.
          -m  MAX
              Display at most the first LIST_MAXCOUNT tasks
              If specified multiple times, the last one wins.
          -P
              Hide priority labels in list output. Use twice to show
              priority labels (default).
          -r
              reverse the display sequence of the listed tasks. Use twice
              to display in normal sequence (default).
EndUsage
  exit
}

# Capture the state of the -+@P options
#
if [ x$HIDE_CONTEXTS_SUBSTITUTION != x ] ; then
  HIDE_CONTEXT_NAMES=1
fi
if [ x$HIDE_PROJECTS_SUBSTITUTION != x ] ; then
  HIDE_PROJECT_NAMES=1
fi
if [ x$HIDE_PRIORITY_SUBSTITUTION != x ] ; then
  HIDE_PRIORITY_LABELS=1
fi
export TODOTXT_LIST_MAXCOUNT=0
export TODOTXT_LIST_REVERSE=0

# == PROCESS OPTIONS ==
LIST_MAX_=0
LIST_REVERSE_=0
LIST_LEN_=0
OPTIND=1
#while getopts "+@Prl:m:" Option
while getopts ":+@Prl:m:" Option
do
  case $Option in
    '@' )
        ## HIDE_CONTEXT_NAMES starts at zero (false); increment it to one
        ##   (true) the first time this flag is seen. Each time the flag
        ##   is seen after that, increment it again so that an even
        ##   number hides project names and an odd number shows project
        ##   names.
        : $(( HIDE_CONTEXT_NAMES++ ))
        if [ $(( $HIDE_CONTEXT_NAMES % 2 )) -eq 0 ]
        then
            ## Zero or even value -- show context names
            unset HIDE_CONTEXTS_SUBSTITUTION
        else
            ## One or odd value -- hide context names
            export HIDE_CONTEXTS_SUBSTITUTION='[[:space:]]@[^[:space:]]\{1,\}'
        fi
        ;;
    '+' )
        ## HIDE_PROJECT_NAMES starts at zero (false); increment it to one
        ##   (true) the first time this flag is seen. Each time the flag
        ##   is seen after that, increment it again so that an even
        ##   number hides project names and an odd number shows project
        ##   names.
        : $(( HIDE_PROJECT_NAMES++ ))
        if [ $(( $HIDE_PROJECT_NAMES % 2 )) -eq 0 ]
        then
            ## Zero or even value -- show project names
            unset HIDE_PROJECTS_SUBSTITUTION
        else
            ## One or odd value -- hide project names
            export HIDE_PROJECTS_SUBSTITUTION='[[:space:]][+][^[:space:]]\{1,\}'
        fi
        ;;
    l )
        LIST_LEN_=$OPTARG
        ;;
    m )
        LIST_MAX_=$OPTARG
        ;;
    P )
        ## HIDE_PRIORITY_LABELS starts at zero (false); increment it to one
        ##   (true) the first time this flag is seen. Each time the flag
        ##   is seen after that, increment it again so that an even
        ##   number hides project names and an odd number shows project
        ##   names.
        : $(( HIDE_PRIORITY_LABELS++ ))
        if [ $(( $HIDE_PRIORITY_LABELS % 2 )) -eq 0 ]
        then
            ## Zero or even value -- show priority labels
            unset HIDE_PRIORITY_SUBSTITUTION
        else
            ## One or odd value -- hide priority labels
            export HIDE_PRIORITY_SUBSTITUTION="([A-Z])[[:space:]]"
        fi
        ;;
    r )
        LIST_REVERSE_=1
        ;;

    '?' )
        echo "Unrecognized option '-$OPTARG'."
        exit
        ;;
  esac
done
shift $(($OPTIND - 1))

# Set TODOTXT_SORT_COMMAND if necessary
#
if [ 0 -lt $LIST_MAX_ ] ; then
  TODOTXT_SORT_COMMAND="$TODOTXT_SORT_COMMAND | head -n $LIST_MAX_"
fi

if [ 0 -lt $LIST_REVERSE_  ] ; then
  TODOTXT_SORT_COMMAND="$TODOTXT_SORT_COMMAND | tail -r"
fi

if [ 10 -lt $LIST_LEN_  ] ; then
  LL1_=$((LIST_LEN_ - 3))
  LL2_=$((LIST_LEN_ - 3 - 4))
  LL1_CMD_="sed 's/^\(\\\\033\[[0-9;]*m\)\(.\{$LL1_\}\).....*\(\\\\033\[[0-9;]*m\)$/\1\2...\3/'"
  LL2_CMD_="sed 's/^\([^\][^0][^3][^3].\{$LL2_\}\).....*$/\1.../'"
  export TODOTXT_FINAL_FILTER="$LL1_CMD_ | $LL2_CMD_"
fi

# Invoke the list command
#
"$TODO_SH" command ls "$@"

exit
