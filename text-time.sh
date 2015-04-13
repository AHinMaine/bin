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
#       Name of font to use for image output
#
#   -S <pointsize>
#
#       Size of font to use for image output
#
#   -C <color>
#
#       Color of font to use for image output
#
#   -B
#
#       Bold font
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
#           * */1 * * *   /perl/bin/text-time.sh -R 0 -B -H -l -t hour
#           * * * * *     /perl/bin/text-time.sh -R 0 -B -H -l -t minute_ones
#           * * * * *     /perl/bin/text-time.sh -R 0 -B -H -C lightblue -S 64 -u -t minute_tens
#           0 0,12 * * *  /perl/bin/text-time.sh -R 270 -B -H -C gray -t ampm_long
# 

_DEF_FONT=Courier
_DEF_FONTSIZE=48
_DEF_FONTCOLOR=white
_DEF_FONTWEIGHT=Normal

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

    if [ -n "${_UPPER}" ] ; then
        _OUT=${1^^}
    elif [ -n "${_LOWER}" ] ; then
        _OUT=${1,,}
    else
        _OUT=${1}
    fi

    if [ -n "${_ROTATE}" -a -n "${_TOKEN}" ] ; then
        echo ${_OUT} | /usr/local/bin/convert -background none -fill ${_FONTCOLOR} -font "${_FONT}${_FONTBOLD:+-Bold}" -pointsize ${_FONTSIZE} -antialias label:@- ${_FONTSHADOW:+\( +clone -shadow 70x4+5+5 \) +swap +flatten} -rotate ${_ROTATE} -trim ${HOME}/text-time-${_TOKEN}.png
    else
        echo ${_OUT}
    fi

}

get_ampm() {

    #     %p    is replaced by national representation of either "ante meridiem" (a.m.)  or "post meridiem" (p.m.)  as appropriate.
    show $(date +'%p')

}


get_ampm_long() {

    #     %p    is replaced by national representation of either "ante meridiem" (a.m.)  or "post meridiem" (p.m.)  as appropriate.
    _ampm=$(date +'%p')

    case $_ampm in
        AM) _p="Ante Meridiem"  ;;
        PM) _p="Post Meridiem"  ;;
        \*) _p="${_ampm}"       ;;
    esac

    show "$_p"

}

get_tzname() {

    #     %Z    is replaced by the time zone name.
    show $(date +'%Z')

}

get_tzoffset() {

    #     %z    is replaced by the time zone offset from UTC; a leading plus sign stands for east of UTC, a minus sign for west of UTC, hours and minutes follow with two digits each and no
    show $(date +'%z')

}

get_minutes() {

    _hour=$(date +'%H')
    _minutes=$(date +'%M')

    if [ "${_hour}" = "00" -a "${_minutes}" = "00" ] ; then

        _m="Midnight"
        _s=""

    elif [ "${_hour}" = "12" -a "${_minutes}" = "00" ] ; then

        _m="Noon"
        _s=""

    else

        case $_minutes in
            00) _m="O'Clock"   ; _s=""   ;;
            01) _m="O'One"     ; _s=""   ;;
            02) _m="O'Two"     ; _s=""   ;;
            03) _m="O'Three"   ; _s=""   ;;
            04) _m="O'Four"    ; _s=""   ;;
            05) _m="O'Five"    ; _s=""   ;;
            06) _m="O'Six"     ; _s=""   ;;
            07) _m="O'Seven"   ; _s=""   ;;
            08) _m="O'Eight"   ; _s=""   ;;
            09) _m="O'Nine"    ; _s=""   ;;
            10) _m="Ten"       ; _s=""   ;;
            11) _m="Eleven"    ; _s=""   ;;
            12) _m="Twelve"    ; _s=""   ;;
            13) _m="Thirteen"  ; _s=""   ;;
            14) _m="Fourteen"  ; _s=""   ;;
            15) _m="Fifteen"   ; _s=""   ;;
            16) _m="Sixteen"   ; _s=""   ;;
            17) _m="Seventeen" ; _s=""   ;;
            18) _m="Eighteen"  ; _s=""   ;;
            19) _m="Nineteen"  ; _s=""   ;;
            20) _m="Twenty"    ; _s=""   ;;
            30) _m="Thirty"    ; _s=""   ;;
            40) _m="Fourty"    ; _s=""   ;;
            50) _m="Fifty"     ; _s=""   ;;
        esac

    fi

    if [ -z "${_m}" ] ; then

        _tens=$(echo $_minutes | cut -c1)
        _ones=$(echo $_minutes | cut -c2)

        case $_tens in
            2) _m="Twenty"  ;;
            3) _m="Thirty"  ;;
            4) _m="Fourty"  ;;
            5) _m="Fifty"   ;;
        esac

        case $_ones in
            1) _s="One"     ;;
            2) _s="Two"     ;;
            3) _s="Three"   ;;
            4) _s="Four"    ;;
            5) _s="Five"    ;;
            6) _s="Six"     ;;
            7) _s="Seven"   ;;
            8) _s="Eight"   ;;
            9) _s="Nine"    ;;
        esac

    fi

    if [ -n "${_SHOWTENS}" ] ; then
        show $_m
    elif [ -n "${_SHOWONES}" ] ; then
        show $_s
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

    #     %l    is replaced by the hour (12-hour clock) as a decimal number (1-12); single digits are preceded by a blank.
    #     %k    is replaced by the hour (24-hour clock) as a decimal number (0-23); single digits are preceded by a blank.
    #     %I    is replaced by the hour (12-hour clock) as a decimal number (01-12).
    #     %H - hour (24)

    _h=$(date +'%I')

    case $_h in
        01) _h="One"    ;;
        02) _h="Two"    ;;
        03) _h="Three"  ;;
        04) _h="Four"   ;;
        05) _h="Five"   ;;
        06) _h="Six"    ;;
        07) _h="Seven"  ;;
        08) _h="Eight"  ;;
        09) _h="Nine"   ;;
        10) _h="Ten"    ;;
        11) _h="Eleven" ;;
        12) _h="Twelve" ;;
    esac

    show $_h

}



get_day() {
    show $(date +'%d')
}

get_day_name() {

    #     %a    is replaced by national representation of the abbreviated weekday name.
    show $(date +'%A')
}

get_day_name_full() {

    #     %A    is replaced by national representation of the full weekday name.
    show $(date +'%A')

}

get_month() {

    #     %d    is replaced by the day of the month as a decimal number (01-31).
    #     %e    is replaced by the day of the month as a decimal number (1-31); single digits are preceded by a blank.
    show $(date +'%d')

}

get_month_name() {

    #     %b    is replaced by national representation of the abbreviated month name.
    show $(date +'%b')

}


get_month_name_full() {

    #     %B    is replaced by national representation of the full month name.
    show $(date +'%B')

}

get_year() {

    # %Y - Year
    show $(date +'%Y')

}


while getopts ulhf:t:R:F:S:C:BH ARGS
    do
        case $ARGS in
            u)  _UPPER="TRUE"                           ;;
            l)  _LOWER="TRUE"                           ;;
            f)  _FORMAT="${OPTARG}"                     ;;
            t)  _TOKEN="${_TOKEN}${_TOKEN:+ }${OPTARG}" ;;

            # ImageMagick related options
            R)  _ROTATE="${OPTARG}"                     ;;
            F)  _FONT="${OPTARG}"                       ;;
            S)  _FONTSIZE="${OPTARG}"                   ;;
            C)  _FONTCOLOR="${OPTARG}"                  ;;
            B)  _FONTBOLD="TRUE"                        ;;
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
    [ -z "${_FONTCOLOR}"  ] && _FONTCOLOR=$_DEF_FONTCOLOR

fi

if [ -n "${_TOKEN}" ] ; then

    # Examples assume the current time is Sunday, April 12, 2015 17:52 US/Eastern

    case $_TOKEN in
               year)   get_year              ;; # 2015
              month)   get_month             ;; # April
         month_name)   get_month_name        ;; # Apr
    month_name_full)   get_month_name_full   ;; # 04
                day)   get_day               ;; # Sunday
           day_name)   get_day_name          ;; # Sun
      day_name_full)   get_day_name_full     ;; # 12
               hour)   get_hour              ;; # 05
        minute_tens)   get_minute_tens       ;; # fifty
        minute_ones)   get_minute_ones       ;; # two
               ampm)   get_ampm              ;; # PM
          ampm_long)   get_ampm_long         ;; # Prime Meridien
             tzname)   get_tzname            ;; # EDT
           tzoffset)   get_tzoffset          ;; # -04:00
    esac

elif [ -n "${_FORMAT}" ] ; then
    show $(date +"${_FORMAT}")
fi


