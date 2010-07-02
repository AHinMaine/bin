#!/bin/bash
#
#===============================================================================
#
#         File:  pruner.sh
#
#        Usage:  pruner.sh
#
#  Description:  Safer file pruning-by-age script
#                Defaults to 90 days.  Ignores any
#                .snapshot directories.
#
#       Author:  Andy Harrison <user=aharrison,tld=com,domain=gmail>
#      Version:  $Id$
#      Created:  04/08/2008 12:41:40 EST
#     Revision:  $Revision$
#===============================================================================

ME=`basename $0`

# {{{ function show_help
#
show_help() {

cat <<SHOWHELP

NAME

    ${ME}

OPTIONS


    [-a <days> ]
        Maximum file age, default 90

    [-s <size> ]
        filesize pattern. See the find(1) manpage
        for acceptable "-size" arguments.

    [-d <dir> ]
        Use specified directory as the base path.
        Default is current.

    [-p <pattern> ]
        A "-name" pattern for find.

    [-l ]
        List-only.  Allows you to preview the list of
        files that will be pruned.  Incompatible with
        the -R option.

    [-R ]
        Remove files as they are found.  Required
        before files will actually be deleted.

    [-- <args> ]
        You can append more find args with --
        Default is ' | xargs -r -0 rm -rf '


EXAMPLES

    ${ME} -a 60 -l
        Display all files greater than 60 days old,
        adding the -ls parameter for the find
        command. (Cannot be combined with -R)

    ${ME} -a 180 -p '*.tar.gz' -d /tmp -R
        Remove all files greater than 180 days old
        with the filename matching '*.tar.gz'
        in the directory /tmp.
        

SHOWHELP

exit

}
#
# }}}

# {{{ getopts
#
while getopts a:Dd:f:hlp:s:RV ARGS
    do
        case ${ARGS} in
            a)  FILEAGE="${OPTARG}"                  ;;
            d)  MYDIR="${MYDIR}${MYDIR:+ }${OPTARG}" ;;
            f)  FIND="${OPTARG}"                     ;;
            l)  LIST="ls"                            ;;
            p)  PATTERN="${OPTARG}"                  ;;
            s)  SIZE="${OPTARG}"                     ;;
            R)  REMOVE=' | xargs -r -0 rm -rf '      ;;
            D)  DEBUG="TRUE"                         ;;
            V)  VERBOSE="TRUE"                       ;;
            h)  show_help                            ;;
           \?)  show_help                            ;;
        esac
    done ; shift `expr ${OPTIND} - 1`

FINDCMD=${FIND:-"`which find 2>/dev/null`"}
if [ ! -x "${FINDCMD}" ] ; then
    echo "No find executable found..."
    exit 1
fi

[ -z "${MYDIR}" ] && MYDIR='.'

[ -n "${DEBUG}" -a -n "${MYDIR}" ] &&
    echo "MYDIR after getopts: ${MYDIR}"

#
# }}}

# {{{ show debug output
#
if [ -n "${DEBUG}" ] ; then
    echo ARGS      = $@
    echo DEBUG     = ${DEBUG}
    echo FILEAGE   = ${FILEAGE}
    echo FINDCMD   = ${FINDCMD}
    echo LIST      = ${LIST:-"print0"}
    echo MYDIR     = ${MYDIR}
    echo REMOVE    = ${REMOVE}
    echo PATTERN   = ${PATTERN}
    echo SIZE      = ${SIZE}
fi
#
# }}}

# {{{ Check directories...
#
# This is just a safety measure to make sure that none of
# these directories are used as bases from which to prune
# files.
#

[ -n "${DEBUG}" ] &&
    echo "FINDDIRS before for loop: ${FINDDIRS}"

for CURDIR in ${FINDDIRS} ; do


    if [ "${CURDIR}" = '.' ] ; then

        [ -n "${DEBUG}" ] &&
            echo "CURDIR matched '.': ${CURDIR}"

        USEPWD=TRUE
        CURDIR=`pwd`

        [ -n "${DEBUG}" ] &&
            echo "CURDIR after pwd: ${CURDIR}"


    fi

    ## Just adding a few common paths from /
    ## and some others for sanity checking...

    case ${CURDIR} in
        "/"                  | \
        "/export"            | \
        "/bin"               | \
        "/dev"               | \
        "/devices"           | \
        "/etc"               | \
        "/home"              | \
        "/ieng"              | \
        "/kernel"            | \
        "/mc"                | \
        "/mnt"               | \
        "/mv"                | \
        "/opt"               | \
        "/platform"          | \
        "/postfix-queues"    | \
        "/proc"              | \
        "/root"              | \
        "/sbin"              | \
        "/usr"               | \
        "/usr/bin"           | \
        "/usr/local/bin"     | \
        "/usr/local/scripts" | \
        "/var"               | \
        "/vol" )

            if [ -z "${REMOVE}" ] ; then

                if [ -d "${CURDIR}" ] && [ -r "${CURDIR}" ] ; then

                    [ -n "${USEPWD}" ] && CURDIR=.

                    FINDPATHS=${FINDPATHS}${FINDPATHS:+ }${CURDIR}

                fi

            else
                echo "Path ${CURDIR} ignored..."
            fi

            ;;

        *)

            [ -n "${DEBUG}"  ]                              &&
                echo "Current match: ${CURDIR}"             &&
                echo "FINDPATHS before: ${FINDPATHS}"       &&
                echo "USEPWD before FINDPATHS: ${USEPWD}"

            if [ -d "${CURDIR}" ] && [ -r "${CURDIR}" ] ; then

                [ -n "${USEPWD}" ] && CURDIR=.

                FINDPATHS=${FINDPATHS}${FINDPATHS:+ }${CURDIR}

            fi

            [ -n "${DEBUG}"  ] &&
                echo "FINDPATHS after: ${FINDPATHS}"

            ;;
    esac

done

[ -n "${DEBUG}"  ] &&
    echo "FINDPATHS after for loop: ${FINDPATHS}"



#
# }}}

# {{{ Look for .prune.age file...
#
# If there is a file in the current directory named
# ".prune.age", then read that for the default file age.
#
if [ -r ".prune.age" ] ; then
    FILEAGE=`head -1 .prune.age`

    [ -n "${DEBUG}" ] &&
        echo Age overridden with .prune.age: ${FILEAGE}

fi
#
# }}}

if [ -z "${FINDPATHS}" ] ; then
    echo
    echo "No paths for find..."
    exit 1
fi

[ -n "${VERBOSE}" ] && echo "Searching paths: ${FINDPATHS}" && echo

if [ -n "${DEBUG}" ] ; then
    printf "pwd = "
    pwd
    echo "Command line to be evaluated:"
    echo \
    eval ${FINDCMD} ${FINDPATHS} -name .snapshot -prune -o ${PATTERN:+" -name '"}${PATTERN}${PATTERN:+"'"} -type f -mtime +${FILEAGE:-'90'} ${SIZE:+" -size +"}${SIZE} -${LIST:-'print0'} ${REMOVE:-"$*"}
else
    eval ${FINDCMD} ${FINDPATHS} -name .snapshot -prune -o ${PATTERN:+" -name '"}${PATTERN}${PATTERN:+"'"} -type f -mtime +${FILEAGE:-'90'} ${SIZE:+" -size +"}${SIZE} -${LIST:-'print0'} ${REMOVE:-"$*"}
fi

# vim: et ts=4 sw=4 nowrap

