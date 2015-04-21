#!/usr/local/bin/bash
#
# NAME
#
#   time-text.sh
#
# DEPENDENCIES
#
#   A recent version of bash is required.  The stock OS X
#   version of bash won't work.  You can install this via
#   brew.  http://brew.sh
#
#   You may need to adjust the shebang path of this script
#   if using something other than brew to install the more
#   recent bash version.
# 
# DESCRIPTION
#
#   This script prints the time as words.  Intended for use
#   with GeekTool to create geeklets ala the Minimalist Text
#   widgets for Android.
#
# OPTIONS
#
#   ( -u | -l )
#
#       Uppercase or Lowercase all characters in string.  By
#       default, the string will be printed as it was
#       received by the date command output.  These options
#       are mutually exclusive with each other.
#
#   -t <token>
#
#       The desired token to output.
#
#       Valid tokens:
#
#           Examples assume the current time is Sunday, April 12, 2015 17:52 US/Eastern
#
#           year            - 2015
#           month_name_full - April
#           month_name      - Apr
#           month           - 04
#           day_name_full   - Sunday
#           day_name        - Sun
#           day             - 12
#           hour            - 05
#           minute_tens     - fifty
#           minute_ones     - two
#           ampm            - PM
#           ampm_long       - Prime Meridien
#           tzname          - EDT
#           tzoffset        - -04:00
#
#   -f <format>
#
#       Pass in a valid format string to be output by the
#       date command. Output will not be in words, but the
#       upper/lower case of output will still happen. See
#       the strftime(3) manpage.  This option is mutually
#       exclusive with the -t option.
#
#   -R <degrees>
#
#       Rotate the image the specified number of degrees.
#       The resulting image will be written to:
#       ${HOME}/text-time-${_TOKEN}.png
#
#       If no rotation is specified, output will be in plain
#       text and can be formatted accordingly.  If rotation
#       is specified, even 0, then the output will be a full
#       image and is subject to ImageMagick formatting with
#       the convert command.
#
#   -F <fontname>
#
#       Name of font to use for image output.  To see the fonts
#       supported by your ImageMagick installation, run:
#
#           convert -list font
#
#   -S <pointsize>
#
#       Size of font to use for image output
#
#   -C <color>
#
#       Color of font to use for image output.
#       (http://www.imagemagick.org/script/color.php)
#
#   -H
#       Font shadow
#
# USAGE
# 
#       Take a look at the Minimalist Text screenshots:
#       https://play.google.com/store/apps/details?id=de.devmil.minimaltext&hl=en
#
#       In order reproduce something like the example of
#       "tenFIFTYnine", you'll actually need three geeklets,
#       hour, tens position of the minute, and ones position
#       of the minute.
#
#       To get those three outputs, create your geeklets to
#       run this script with different arguments.
#
#       geeklet 1:    text-time.sh -t hour -l         # ten
#       geeklet 2:    text-time.sh -t minute_tens -u  # FIFTY
#       geeklet 3:    text-time.sh -t minute_ones -l  # nine
#   
#
#       If CPU/battery consumption is too excessive, instead use cron jobs to
#       update the time images:
#
#           * */1 * * *   text-time.sh -R 0   -H                          -l -t hour            2>/dev/null
#           * * * * *     text-time.sh -R 0   -H                          -l -t minute_ones     2>/dev/null
#           * * * * *     text-time.sh -R 0   -H -C lightblue -S 64       -u -t minute_tens     2>/dev/null
#           0 0,12 * * *  text-time.sh -R 270 -H -C lightgray                -t ampm_long       2>/dev/null
#           0 0 1 * *     text-time.sh -R 90  -H                          -u -t month_name      2>/dev/null
#           0 0 * * *     text-time.sh -R 0   -H -C lightblue -S 98 -K -5 -u -t day             2>/dev/null
#           0 0 * * *     text-time.sh -R 0   -H -C lightgray -S 36       -u -t day_name_full   2>/dev/null


_DEF_FONT=Courier-Bold
_DEF_FONTSIZE=48
_DEF_FONTKERN=1
_DEF_FONTCOLOR=white
_DEF_FONTWEIGHT=Normal
_DEF_OUTPUT=/var/tmp/`whoami`/text-time

show_help() {

    echo
    echo "-u all uppercase"
    echo "-l all lowercase"
    echo "-t [year|month_name_full|month_name|month|day_name_full|day_name|day|hour|minute_tens|minute_ones]"
    echo "-f <format string> (see strftime(3) for format values)"
    echo
    echo "More usage details in the header comments of the script."
    echo

    exit 0

}

show() {

    _TEXT="${_OVERRIDE:-$1}"

    if [ -n "${_UPPER}" ] ; then
        _OUT="${_TEXT^^}"
    elif [ -n "${_LOWER}" ] ; then
        _OUT="${_TEXT,,}"
    else
        _OUT="${_TEXT}"
    fi

    if [ -n "${_ROTATE}" -a -n "${_TOKEN}" ] ; then

        [ -n "${VERBOSE}" ] && set -x

        echo "${_OUT}" | \
            /usr/local/bin/convert \
                -background none \
                -fill ${_FONTCOLOR} \
                -font "${_FONT}" \
                -kerning ${_FONTKERN} \
                -gravity South \
                -pointsize ${_FONTSIZE} \
                -antialias label:@- ${_FONTSHADOW:+\( +clone -shadow 70x5+5+5 \) +swap +flatten} \
                -rotate ${_ROTATE} \
                -trim ${_DEF_OUTPUT}/text-time-${_TOKEN}.png

        [ -n "${VERBOSE}" ] && set +x

    else
        echo "${_OUT}"
    fi

}

get_ampm() {

    if [ -n "${_T24}" ] ; then
        show " "
    fi

    show $(date +'%p')

}

get_ampm_long() {

    if [ -n "${_T24}" ] ; then
        show " "
    fi

    _ampm=$(date +'%p')

    case $_ampm in
        AM) _p="Ante Meridiem"  ;;
        PM) _p="Post Meridiem"  ;;
        \*) _p="${_ampm}"       ;;
    esac

    show "$_p"

}


get_minutes() {

    _hour=$(date +'%H')
    _minutes=$(date +'%M')

    if [ "${_hour}" = "00" -a "${_minutes}" = "00" ] ; then

        if [ -n "${_T24}" ] ; then
            _M="Hundred"
            _m=""
        else
            _M="Midnight"
            _m=""
        fi

    elif [ "${_hour}" = "12" -a "${_minutes}" = "00" ] ; then

        _M="Noon"
        _m=""

    else

        case $_minutes in
            00) _M="O'Clock"   ; _m=""   ;;
            01) _M="O'One"     ; _m=""   ;;
            02) _M="O'Two"     ; _m=""   ;;
            03) _M="O'Three"   ; _m=""   ;;
            04) _M="O'Four"    ; _m=""   ;;
            05) _M="O'Five"    ; _m=""   ;;
            06) _M="O'Six"     ; _m=""   ;;
            07) _M="O'Seven"   ; _m=""   ;;
            08) _M="O'Eight"   ; _m=""   ;;
            09) _M="O'Nine"    ; _m=""   ;;
            10) _M="Ten"       ; _m=""   ;;
            11) _M="Eleven"    ; _m=""   ;;
            12) _M="Twelve"    ; _m=""   ;;
            13) _M="Thirteen"  ; _m=""   ;;
            14) _M="Fourteen"  ; _m=""   ;;
            15) _M="Fifteen"   ; _m=""   ;;
            16) _M="Sixteen"   ; _m=""   ;;
            17) _M="Seventeen" ; _m=""   ;;
            18) _M="Eighteen"  ; _m=""   ;;
            19) _M="Nineteen"  ; _m=""   ;;
            20) _M="Twenty"    ; _m=""   ;;
            30) _M="Thirty"    ; _m=""   ;;
            40) _M="Fourty"    ; _m=""   ;;
            50) _M="Fifty"     ; _m=""   ;;
        esac

    fi

    if [ -z "${_M}" ] ; then

        _tens=$(echo $_minutes | cut -c1)
        _ones=$(echo $_minutes | cut -c2)

        case $_tens in
            2) _M="Twenty"  ;;
            3) _M="Thirty"  ;;
            4) _M="Fourty"  ;;
            5) _M="Fifty"   ;;
        esac

        case $_ones in
            1) _m="One"     ;;
            2) _m="Two"     ;;
            3) _m="Three"   ;;
            4) _m="Four"    ;;
            5) _m="Five"    ;;
            6) _m="Six"     ;;
            7) _m="Seven"   ;;
            8) _m="Eight"   ;;
            9) _m="Nine"    ;;
        esac

    fi

    if [ -n "${_SHOWTENS}" ] ; then
        show $_M
    elif [ -n "${_SHOWONES}" ] ; then
        show $_m
    fi

}


get_minute_ones() {

    _SHOWONES="TRUE"
    get_minutes

}


get_minute_tens() {

    _SHOWTENS="TRUE"
    get_minutes

}



get_hour() {

    if [ -n "${_T24}" ] ; then
        _h=$(date +'%H')
    else
        _h=$(date +'%I')
    fi

    case $_h in
        00) _h="Zero"         ;;
        01) _h="One"          ;;
        02) _h="Two"          ;;
        03) _h="Three"        ;;
        04) _h="Four"         ;;
        05) _h="Five"         ;;
        06) _h="Six"          ;;
        07) _h="Seven"        ;;
        08) _h="Eight"        ;;
        09) _h="Nine"         ;;
        10) _h="Ten"          ;;
        11) _h="Eleven"       ;;
        12) _h="Twelve"       ;;
        13) _h="Thirteen"     ;;
        14) _h="Fourteen"     ;;
        15) _h="Fifteen"      ;;
        16) _h="Sixteen"      ;;
        17) _h="Seventeen"    ;;
        18) _h="Eighteen"     ;;
        19) _h="Nineteen"     ;;
        20) _h="Twenty"       ;;
        21) _h="Twenty One"   ;;
        22) _h="Twenty Two"   ;;
        23) _h="Twenty Three" ;;
    esac

    show $_h

}



while getopts ulhf:t:R:F:S:K:C:HO:T ARGS
    do
        case $ARGS in
            # Output options
            t)  _TOKEN="${_TOKEN}${_TOKEN:+ }${OPTARG}" ;;
            f)  _FORMAT="${OPTARG}"                     ;;
            O)  _OVERRIDE="${OPTARG}"                   ;;
            u)  _UPPER="TRUE"                           ;;
            l)  _LOWER="TRUE"                           ;;
            T)  _T24="TRUE"                             ;;

            # ImageMagick related options
            R)  _ROTATE="${OPTARG}"                     ;;
            F)  _FONT="${OPTARG}"                       ;;
            S)  _FONTSIZE="${OPTARG}"                   ;;
            K)  _FONTKERN="${OPTARG}"                   ;;
            C)  _FONTCOLOR="${OPTARG}"                  ;;
            H)  _FONTSHADOW="TRUE"                      ;;

            h)  show_help && exit 0                     ;;
           \?)  show_help && exit 1                     ;;
        esac
    done ; shift `expr ${OPTIND} - 1`


if [ -z "${_TOKEN}" -a -z "${_FORMAT}" ] ; then
    echo "No token -t or format -f option specified"
    show_help
fi

if [ -n "${_ROTATE}" ] ; then

    if [ ! -x "/usr/local/bin/convert" ] ; then
        echo "ImageMagic not installed. Aborting."
        exit 1
    fi

    [ -z "${_FONT}"       ] && _FONT=$_DEF_FONT
    [ -z "${_FONTSIZE}"   ] && _FONTSIZE=$_DEF_FONTSIZE
    [ -z "${_FONTKERN}"   ] && _FONTKERN=$_DEF_FONTKERN
    [ -z "${_FONTCOLOR}"  ] && _FONTCOLOR=$_DEF_FONTCOLOR

fi

if [ ! -d "${_DEF_OUTPUT}" ] ; then
    mkdir -p "${_DEF_OUTPUT}"
    chmod 700 "${_DEF_OUTPUT}"
fi

if [ ! -w "${_DEF_OUTPUT}" ] ; then
    echo "Problem creating image output directory. Aborting."
    exit 1
fi

if [ -n "${_TOKEN}" ] ; then

    # Examples assume the current time is Sunday, April 12, 2015 17:52 US/Eastern

    case $_TOKEN in
             tzname)   show $(date +'%Z')    ;; # EDT
           tzoffset)   show $(date +'%z')    ;; # -04:00
               year)   show $(date +'%Y')    ;; # 2015
              month)   show $(date +'%m')    ;; # April
         month_name)   show $(date +'%b')    ;; # Apr
    month_name_full)   show $(date +'%B')    ;; # 04
                day)   show $(date +'%d')    ;; # Sunday
           day_name)   show $(date +'%A')    ;; # Sun
      day_name_full)   show $(date +'%A')    ;; # 12
               hour)   get_hour              ;; # 05
        minute_tens)   get_minute_tens       ;; # fifty
        minute_ones)   get_minute_ones       ;; # two
               ampm)   get_ampm              ;; # PM
          ampm_long)   get_ampm_long         ;; # Prime Meridien
    esac

elif [ -n "${_FORMAT}" ] ; then
    show $(date +"${_FORMAT}")
fi


