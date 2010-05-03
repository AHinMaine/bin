#!/bin/sh

if [ -x "/opt/local/bin/perltidy" ] ; then
    PT=/opt/local/bin/perltidy
else
    PT="`which perltidy`"
fi

if [ ! -x "${PT}" ] ; then
    echo "perltidy executable not found..."
    exit 1
fi

pbp_style() {

    # Perl Best Practices style

    ${PT}                                               \
        --block-brace-tightness=1                       \
        --brace-tightness=1                             \
        --closing-token-indentation=0                   \
        --continuation-indentation=4                    \
        --indent-columns=4                              \
        --maximum-fields-per-table=1                    \
        --maximum-line-length=${WIDTH}                  \
        --nooutdent-long-quotes                         \
        --nospace-for-semicolon                         \
        --paren-tightness=1                             \
        --square-bracket-tightness=1                    \
        --standard-error-output                         \
        --standard-output                               \
        --vertical-tightness=2                          \
        --want-break-before="% + - * / x != == >= <= =~ !~ < > | & >= <= **= += *= &= <<= &&= -= /= |= >>= ||= .= %= ^= x=" \
        --want-right-space="!"                          \
         ${FILE}

}

test_style_old() {

    ${PT}                                               \
        --block-brace-tightness=1                       \
        --closing-token-indentation=0                   \
        --continuation-indentation=33                   \
        --cuddled-else                                  \
        --indent-columns=4                              \
        --line-up-parentheses                           \
        --maximum-fields-per-table=1                    \
        --nooutdent-long-quotes                         \
        --nooutdent-labels                              \
        --noopening-anonymous-sub-brace-on-new-line     \
        --noopening-brace-on-new-line                   \
        --opening-brace-always-on-right                 \
        --noopening-sub-brace-on-new-line               \
        --nospace-for-semicolon                         \
        --standard-error-output                         \
        --standard-output                               \
        --trim-qw                                       \
        --vertical-tightness=1                          \
        --vertical-tightness-closing=1                  \
        ${FILE}

}

test_style() {

    ${PT}                                               \
        --add-newlines                                  \
        --blanks-before-blocks                          \
        --blanks-before-comments                        \
        --blanks-before-subs                            \
        --block-brace-tightness=1                       \
        --brace-tightness=1                             \
        --break-at-old-logical-breakpoints              \
        --break-at-old-keyword-breakpoints              \
        --break-at-old-ternary-breakpoints              \
        --closing-token-indentation=1                   \
        --comma-arrow-breakpoints=3                     \
        --continuation-indentation=4                    \
        --cuddled-else                                  \
        --indent-columns=4                              \
        --line-up-parentheses                           \
        --maximum-fields-per-table=1                    \
        --maximum-line-length=${WIDTH}                  \
        --noopening-brace-on-new-line                   \
        --noopening-sub-brace-on-new-line               \
        --nooutdent-labels                              \
        --nooutdent-long-quotes                         \
        --opening-brace-always-on-right                 \
        --paren-tightness=1                             \
        --square-bracket-tightness=1                    \
        --stack-opening-tokens                          \
        --stack-closing-tokens                          \
        --standard-error-output                         \
        --standard-output                               \
        --trim-qw                                       \
        --vertical-tightness=2                          \
        --vertical-tightness-closing=1                  \
        --want-break-before="."                         \
        --want-right-space="!"                          \
        ${FILE}


}

my_style() {

    ${PT}                                               \
        --add-newlines                                  \
        --blanks-before-blocks                          \
        --blanks-before-comments                        \
        --blanks-before-subs                            \
        --block-brace-tightness=1                       \
        --brace-tightness=1                             \
        --closing-token-indentation=1                   \
        --comma-arrow-breakpoints=0                     \
        --continuation-indentation=4                    \
        --cuddled-else                                  \
        --indent-columns=4                              \
        --line-up-parentheses                           \
        --maximum-fields-per-table=1                    \
        --maximum-line-length=${WIDTH}                  \
        --noopening-brace-on-new-line                   \
        --noopening-sub-brace-on-new-line               \
        --nooutdent-labels                              \
        --nooutdent-long-quotes                         \
        --opening-brace-always-on-right                 \
        --paren-tightness=1                             \
        --square-bracket-tightness=1                    \
        --standard-error-output                         \
        --standard-output                               \
        --trim-qw                                       \
        --vertical-tightness=0                          \
        --vertical-tightness-closing=0                  \
        --want-break-before="."                         \
        --want-right-space="!"                          \
        ${FILE}


}

whitesmiths_style() {

    # similar to the Whitesmith's C style

    ${PT}                                               \
        --brace-left-and-indent                         \
        --brace-left-and-indent-list="if elsif else unless for foreach sub while until do continue : BEGIN END CHECK INIT AUTOLOAD DESTROY"        \
        --brace-vertical-tightness=1                    \
        --brace-vertical-tightness-closing=1            \
        --break-at-old-comma-breakpoints                \
        --continuation-indentation=4                    \
        --indent-closing-paren                          \
        --indent-columns=4                              \
        --line-up-parentheses                           \
        --long-block-line-count=2                       \
        --maximum-consecutive-blank-lines=2             \
        --maximum-line-length=${WIDTH}                  \
        --nocheck-syntax                                \
        --nooutdent-labels                              \
        --nooutdent-long-lines                          \
        --paren-vertical-tightness=1                    \
        --paren-vertical-tightness-closing=1            \
        --space-for-semicolon                           \
        --square-bracket-vertical-tightness=1           \
        --square-bracket-vertical-tightness-closing=1   \
        --standard-error-output                         \
        --standard-output                               \
        --warning-output                                \
        -wbb="% + - * / x != == >= <= =~ !~ < > | & >= < = **= += *= &= <<= &&= -= /= |= >>= ||= .= %= ^= x=" \
        ${FILE}

}

aaron_style() {

    # similar to the Whitesmith's C style

       #--brace-left-and-indent                         \
       #--brace-left-and-indent-list="if elsif else unless for foreach sub while until do continue : BEGIN END CHECK INIT AUTOLOAD DESTROY"        \

    ${PT}                                               \
        --opening-brace-on-new-line                     \
        --opening-sub-brace-on-new-line                 \
        --brace-vertical-tightness=1                    \
        --brace-vertical-tightness-closing=0            \
        --break-at-old-comma-breakpoints                \
        --continuation-indentation=4                    \
        --indent-closing-paren                          \
        --indent-columns=4                              \
        --line-up-parentheses                           \
        --long-block-line-count=2                       \
        --maximum-consecutive-blank-lines=2             \
        --maximum-line-length=${WIDTH}                  \
        --nocheck-syntax                                \
        --nooutdent-labels                              \
        --nooutdent-long-lines                          \
        --paren-vertical-tightness=1                    \
        --paren-vertical-tightness-closing=0            \
        --space-for-semicolon                           \
        --square-bracket-vertical-tightness=1           \
        --square-bracket-vertical-tightness-closing=0   \
        --standard-error-output                         \
        --standard-output                               \
        --warning-output                                \
        -wbb="% + - * / x != == >= <= =~ !~ < > | & >= < = **= += *= &= <<= &&= -= /= |= >>= ||= .= %= ^= x=" \
        ${FILE}

}

gnu_style() {

    ${PT}                                               \
        --gnu-style                                     \
        --standard-error-output                         \
        --standard-output                               \
        --warning-output                                \
        ${FILE}

}

show_help() {
    
cat <<SHOWHELP


NAME

    pt.sh

DESCRIPTION

    Wrapper for the perltidy program to use different styles.

OPTIONS

    -m

        My personal style preference.  This is the default.

    -p

        Perl Best Practices style

    -w

        Whitesmith's style.  Very c-ish.
     -g

        GNU style.  Very c-ish.
    -a

        My boss' c-ish style

    -t

        Test style

    -f <filename>

        Filename of perl script to tidy up.

    -c <columns> (default: 80)

        Column width

    -M

        Max width.  Attempts to determine the actual
        width of your screen and use that as the 
        column width.




SHOWHELP

exit 0

}

while getopts ac:qMmpwtgf:l:DH STYLE
    do
        case ${STYLE} in
            f)  FILE="${OPTARG}"        ;;
            c)  WIDTH="${OPTARG}"       ;;
            M)  MAXWIDTH="TRUE"         ;;
            m)  DO="my_style"           ;;
            p)  DO="pbp_style"          ;;
            t)  DO="test_style"         ;;
            w)  DO="whitesmiths_style"  ;;
            a)  DO="aaron_style"        ;;
            g)  DO="gnu_style"          ;;
            D)  DEBUG="true"            ;;
            H)  show_help               ;;
           \?)  DO="my_style"           ;;
        esac
    done

if [ -z "${DO}" ] ; then
    DO="my_style"
fi

if [ -z "${WIDTH}" ] ; then
    WIDTH="80"
fi

if [ -n "${MAXWIDTH}" ] ; then
    WIDTH="`stty size | awk '{print $2}'`"
    WIDTH="`expr ${WIDTH} - 10`"
fi

if [ -n "${DEBUG}" ] ; then
    echo "# Width = ${WIDTH}"
    echo "# Style = ${DO}"
fi

${DO} 

