#!/bin/bash
# shellcheck shell=bash
# shellcheck disable=SC2034,SC2183,SC2154,SC1091
clear
echo "Loading..."
# shellcheck disable=SC2064
detect_ext_data() {
    if touch /sdcard/.rw && rm /sdcard/.rw; then
        export EXT_DATA="/sdcard/FontManager"
    elif touch /storage/emulated/0/.rw && rm /storage/emulated/0/.rw; then
        export EXT_DATA="/storage/emulated/0/FontManager"
    elif touch /data/media/0/.rw && rm /data/media/0/.rw; then
        export EXT_DATA="/data/media/0/FontManager"
    else
        EXT_DATA='/data/local/tmp/FontManager'
        echo -e "⚠ Possible internal storage access issues! Please make sure data is mounted and decrypted."
        echo -e "⚠ Trying to proceed anyway "
        sleep 2
    fi
}
detect_ext_data
if test ! -d "$EXT_DATA"; then
    mkdir -p "$EXT_DATA" >/dev/null
fi
if ! touch "$EXT_DATA"/.rw && rm -fr "$EXT_DATA"/.rw; then
    if ! rm -fr "$EXT_DATA" && mkdir -p "$EXT_DATA" && touch "$EXT_DATA"/.rw && rm -fr "$EXT_DATA"/.rw; then
        echo -e "⚠ Cannot access internal storage! Falling back to module directory"
        EXT_DATA="/data/adb/modules/fontrevival"
    fi
fi
mkdir -p "$EXT_DATA"/logs >/dev/null
mkdir -p "$EXT_DATA"/lists >/dev/null
mkdir -p "$EXT_DATA"/font >/dev/null
mkdir -p "$EXT_DATA"/emoji >/dev/null
MODDIR="/data/adb/modules/fontrevival"
set -o functrace
shopt -s checkwinsize
shopt -s expand_aliases
# Source necessary files
alias curl='$MODDIR/tools/curl --dns-servers 1.1.1.1,8.8.8.8'
. /data/adb/modules/fontrevival/tools/utils
. /data/adb/modules/fontrevival/tools/apiClient
log 'INFO' "Welcome to Font Manager"
initClient
if test "$GUI" == 1; then
    log 'INFO' "Running in GUI mode"
    echo "GUI mode is not supported in production builds"
    exit 1
else
    log 'INFO' "Running in CLI mode"
fi
# shellcheck disable=SC2154
if test -n "${ANDROID_SOCKET_adbd}"; then
    log 'ERROR' "Cannot run via adb"
    echo -e "ⓧ Please run this in a terminal emulator on device! ⓧ"
    exit 1
fi
if test "$(id -u)" -ne 0; then
    log 'ERROR' "Effective user ID is not 0"
    echo -e "${R} Please run this script as root!${N}"
    exit 1
fi
if ! $NR; then
    log 'ERROR' "Could not determine if this script was called correctly"
    echo -e "${R} Do not call this script directly! Instead call just 'manage_fonts'${N}"
    it_failed
fi
TRY_COUNT=1
font_select() {
    log 'INFO' "Received request to select fonts"
    clear
    do_banner
    sleep 0.5
    echo -e "${Bl} Font changer selected.${N}"
    echo -e "${B} USAGE:${N}"
    echo -e "${B} <number>: Selects that font${N}"
    echo -e "${B} <enter/return>: Shows more fonts${N}"
    echo -e "${B} x: goes back to main menu${N}"
    echo -e "${B} q: quits${N}"
    echo -e "${Bl} Press enter/return to continue${N}"
    echo -e "$div"
    read -r -p "> " -n 1 -s
    LINESTART=1
    print_list() {
        do_banner
        TOTALLINES=$(wc -l /sdcard/FontManager/lists/fonts.list | awk '{ print $1 }')
        USABlELINES=$((LINES - 15))
        LINESREAD=$((LINESTART + USABlELINES))
        if test $LINESTART -ge "$TOTALLINES"; then
            LINESTART=1
            LINESREAD=$USABlELINES
        fi
        awk '{printf "\033[47;100m%d.\t%s\n", NR, $0}' <"$MODDIR"/lists/fonts.list | sed -n ${LINESTART},${LINESREAD}p
        echo -e "$div"
        echo -e "${Bl} x: main menu, q: quit, <enter>: more, <number>: select"
        echo -en " Your choice: "
        unset a
        read -r a
        if test "$a" == ""; then
            LINESTART=$((LINESTART + USABlELINES))
            print_list
        fi
    }
    print_list
    if test "$a" == "q"; then
        do_quit
    elif test "$a" == "x"; then
        do_banner
        echo -e "${Y} Going to main menu ${N}"
        sleep 1
        menu_set
    fi
    choice=$(sed "${a}q;d" "$MODDIR"/lists/fonts.list)
    if [[ -z $choice ]]; then
        do_banner
        echo -e "${R} ERROR: INVALID SELECTION${N}"
        sleep 0.5
        echo -e "${Y} Please try again${N}"
        sleep 3
        font_select
    fi
    do_banner
    echo -e "${Bl} Downloading $choice font..."
    # downloadFile 'fonts' "$choice" 'zip' "$EXT_DATA/font/$choice.zip"
    sleep 1
    in_f() {
        RESULTF="$EXT_DATA"/font/"$choice".zip
        if [ ! -f "$RESULTF" ]; then
            echo -e "${R} Downloaded file not found. The font was not installed.${N}"
            echo -e "${R} Returning to main menu in three seconds${N}"
            pkill -f curl
            sleep 3
            menu_set
            return
        fi
        unzip -o "$RESULTF" -d "$MODDIR/system/fonts" &>/dev/null
        set_perm_recursive 644 root root 0 "$MODDIR"/system/fonts/*
        if test -d /product/fonts; then
            mkdir -p "$MODDIR"/system/product/fonts
            cp "$MODDIR"/system/fonts/* "$MODDIR"/system/product/fonts/
            set_perm_recursive 644 root root 0 "$MODDIR"/system/product/fonts/*
        fi
        if test -d /system_ext/fonts; then
            mkdir -p "$MODDIR"/system/system_ext/fonts
            cp "$MODDIR"/system/fonts/* "$MODDIR"/system/system_ext/fonts/
            set_perm_recursive 644 root root 0 "$MODDIR"/system/system_ext/fonts/*
        fi
        echo "$choice" >"$MODDIR"/cfont
        sleep 1.5
    }
    in_f &
    echo -e "${Bl} Installing $choice font..."
    echo -e " "
    echo -e "${Bl} Install success!${N}"
    sleep 2
    reboot_fn
}
emoji_select() {
    log 'INFO' "Received request to select emojis"
    clear
    do_banner
    sleep 0.5
    echo -e "${Bl} Emoji changer selected. Please type the appropriate number when prompted.${N}"
    echo -e "${B} USAGE:${N}"
    echo -e "${B} <number>: Selects that font${N}"
    echo -e "${B} <enter/return>: Shows more fonts${N}"
    echo -e "${B} x: goes back to main menu${N}"
    echo -e "${B} q: quits${N}"
    echo -e "${Bl} Press enter/return to continue${N}"
    echo -e "$div"
    read -r -p "> " -n 1 -s
    LINESTART=1
    print_list() {
        do_banner
        TOTALLINES=$(wc -l /sdcard/FontManager/lists/emojis.list | awk '{ print $1 }')
        USABlELINES=$((LINES - 15))
        LINESREAD=$((LINESTART + USABlELINES))
        if test $LINESTART -ge "$TOTALLINES"; then
            LINESTART=1
            LINESREAD=$USABlELINES
        fi
        awk '{printf "\033[47;100m%d.\t%s\n", NR, $0}' <"$MODDIR"/lists/emojis.list | sed -n ${LINESTART},${LINESREAD}p
        echo -e "$div"
        echo -e "${Bl} x: main menu, q: quit, <enter>: more, <number>: select"
        echo -en " Your choice: "
        unset a
        read -r a
        if test "$a" == ""; then
            LINESTART=$((LINESTART + USABlELINES))
            print_list
        fi
    }
    print_list
    if test "$a" == "q"; then
        do_quit
    elif test "$a" == "x"; then
        do_banner
        echo -e "${Y} Going to main menu ${N}"
        sleep 1
        menu_set
    fi
    choice=$(sed "${a}q;d" "$MODDIR"/lists/emojis.list)
    if [[ -z $choice ]]; then
        do_banner
        echo -e "${R} ERROR: INVALID SELECTION${N}"
        sleep 0.5
        echo -e "${Y} Please try again${N}"
        sleep 3
        font_select
    fi
    do_banner
    echo -e "${Bl} Downloading $choice emoji set...."
    # downloadFile 'emojis' "$choice" 'zip' "$EXT_DATA/emoji/$choice.zip"
    sleep 1
    in_e() {
        RESULTE="$EXT_DATA"/emoji/"$choice".zip
        if [ ! -f "$RESULTE" ]; then
            echo -e "${R} Downloaded file not found. The emoji set was not installed.${N}"
            echo -e "${R} Returning to main menu in three seconds ${N}"
            pkill -f curl
            sleep 3
            menu_set
            return
        fi
        unzip -o "$RESULTE" -d "$MODDIR/system/fonts" &>/dev/null
        set_perm_recursive 644 root root 0 "$MODDIR"/system/fonts/*
        if test -d /product/fonts; then
            mkdir -p "$MODDIR"/system/product/fonts
            cp "$MODDIR"/system/fonts/* "$MODDIR"/system/product/fonts/
            set_perm_recursive 644 root root 0 "$MODDIR"/system/product/fonts/*
        fi
        if test -d /system_ext/fonts; then
            mkdir -p "$MODDIR"/system/system_ext/fonts
            cp "$MODDIR"/system/fonts/* "$MODDIR"/system/system_ext/fonts/
            set_perm_recursive 644 root root 0 "$MODDIR"/system/system_ext/fonts/*
        fi
        if test -d /data/data/com.facebook.orca; then
            if test -d /data/data/com.facebook.orca/app_compactdisk/ras_blobs/latest/sessionless/storage; then
                cp -f "$MODDIR/system/fonts/NotoColorEmoji.ttf" "/data/data/com.facebook.orca/app_compactdisk/ras_blobs/latest/sessionless/storage/FacebookEmoji.ttf"
                FBID="$(dumpsys package com.facebook.orca | grep userId= | sed 's/[^0-9]*//g')"
                set_perm 644 "$FBID" "$FBID" 0 "/data/data/com.facebook.orca/app_compactdisk/ras_blobs/latest/sessionless/storage/FacebookEmoji.ttf"
            fi
        fi
        echo "$choice" >"$MODDIR"/cemoji
        sleep 1.5
    }
    in_e &
    echo -e "${Bl} Installing $choice emoji set..."
    echo -e " "
    echo -e "${Bl} Install success!${N}"
    sleep 2
    reboot_fn
}
get_id() {
    sed -n 's/^name=//p' "${1}"
}
detect_others() {
    log 'INFO' "Running conflicts check"
    for i in /data/adb/modules/*/*; do
        if test "$i" != "*fontrevival" && test ! -f "$i"/disaBle && test -d "$i"/system/fonts; then
            NAME=$(get_id "$i"/module.prop)
            echo -e "${R} ⚠ ${N}"
            echo -e "${R} ⚠ Module editing font or emoji detected${N}"
            echo -e "${R} ⚠ Module - $NAME${N}"
            echo -e "${R} ⚠ Please remove said module and retry${N}"
            log 'ERROR' "Found conflicting module: $NAME"
            sleep 4
            it_failed
        fi
    done
}
reboot_fn() {
    log 'INFO' "Getting reaady to reboot"
    do_banner
    echo -e "${Bl} Do you want to reboot now?${N}"
    echo -e "${Bl} Make sure to save your work!${N}"
    echo -en "${Bl} y: yes, n: return to menu: "
    read -r a
    if test "$a" == "y"; then
        log 'INFO' "Going down for reboot"
        /system/bin/svc power reboot || /system/bin/reboot || setprop sys.powerctl reboot
    else
        log 'INFO' "Reboot request canceled"
        echo -e "${Y} Reboot cancelled. Returning to menu.${N}"
        sleep 2
        menu_set
    fi
}
rever_st() {
    log 'INFO' "Received request to remove all custom fonts"
    do_banner
    r_s() {
        rm -fr "$MODDIR"/system/fonts/*
        rm -fr "$MODDIR"/system/*/fonts/*
        rm -fr "$MODDIR"/c*
        sleep 1.5
    }
    r_s &
    echo -i "${Bl} Reverting to stock fonts ${N}..."
    echo -e "\n${Bl} Stock fonts applied! Please reboot.${N}"
    sleep 1
    reboot_fn
}
open_link() {
    log 'INFO' "Opening link: $1"
    do_banner
    echo -e "${Bl} Opening https://www.androidacy.com/$1/...${N}"
    sleep 1
    # am start -a android.intent.action.VIEW -d "https://www.androidacy.com/$1/?utm_source=FontManager&utm_medium=modules" &>/dev/null
    sleep 2
    echo -e "${Bl} Page should be open. Returning to menu.${N}"
    sleep 2
    menu_set
}
custom_font() {
    log 'INFO' "Received request to install custom font"
    do_banner
    echo -e "${R} Custom fonts selected. Please note, we do not offer font patching, so please verify that the font you are installing works correctly on your device.${N}"
    echo -e "${R} This feature is currently in beta and may not work properly.${N}"
    echo -e "${Bl} Press enter to continue: ${N}"
    read -r a
    local custFontLoc="$EXT_DATA/custom_fonts"
    FONT_CUST=false
    EMOJI_CUST=false
    if test -d "$custFontLoc"; then
        # Test for Bold, Regular, Italic
        if test -f "$custFontLoc/Bold.ttf" && test -f "$custFontLoc/Regular.ttf" && test -f "$custFontLoc/Italic.ttf"; then
            FONT_CUST=true
            echo -e "${Bl} Using custom font${N}"
            cp -f "$custFontLoc/Bold.ttf" "$MODDIR"/system/fonts/Roboto-Bold.ttf
            cp -f "$custFontLoc/Regular.ttf" "$MODDIR"/system/fonts/Roboto-Regular.ttf
            cp -f "$custFontLoc/Italic.ttf" "$MODDIR"/system/fonts/Roboto-Italic.ttf
            cp -f "$custFontLoc/Italic.ttf" "$MODDIR"/system/product/fonts/Roboto-BoldItalic.ttf
            echo -e "${Bl} Custom font applied! Please reboot.${N}"
            echo -e "${Bl} ⚠ Please note that this is a custom font, and not supported by Androidacy. We make no guarantees that it will work with your device. If you want tried and tested fonts, please select one of the ones we provide.${N}"
            echo 'custom' >"$MODDIR"/cfont
            sleep 2
        fi
        # Same but for Emoji.ttf
        if test -f "$custFontLoc/Emoji.ttf"; then
            EMOJI_CUST=true
            echo -e "${Bl} Using custom emoji${N}"
            cp -f "$custFontLoc/Emoji.ttf" "$MODDIR"/system/fonts/NotoColorEmoji.ttf
            echo -e "${Bl} Custom emoji applied! Please reboot.${N}"
            echo -e "${Bl} ⚠ Please note that this is a custom emoji, and not supported by Androidacy. We make no guarantees that it will work with your device. If you want tried and tested fonts, please select one of the ones we provide.${N}"
            echo 'custom' >"$MODDIR"/cemoji
            sleep 2
        fi
        if ! $FONT_CUST && ! $EMOJI_CUST; then
            echo -e "${R} ⚠ ${N}"
            echo -e "${R} ⚠ No custom font or emoji found${N}"
            echo -e "${R} ⚠ Please try again${N}"
            sleep 2
            menu_set
        fi
    else
        mkdir -p "$custFontLoc"
        echo -e "${R} ⚠ ${N}"
        echo -e "${R} ⚠ Created custom font directory${N}"
        echo -e "${R} ⚠ Copy your custom font files to this directory: $custFontLoc${N}"
        echo -e "${R} ⚠ For fonts, you need to have Bold, Regular, Italic ttf files, each named as such: Bold.ttf, Regular.ttf, Italic.ttf${N}"
        echo -e "${R} ⚠ For Emoji, you need to have Emoji.ttf, each named as such: Emoji.ttf${N}"
        sleep 4
        menu_set
    fi
    sleep 4
    menu_set
}
menu_set() {
    log 'INFO' "Showing main menu"
    while :; do
        do_banner
        for i in font emoji; do
            if test ! -f $MODDIR/c$i; then
                echo "stock" >$MODDIR/c$i
            fi
        done
        echo -e "${Bl} Current font: $(cat $MODDIR/cfont)${N}"
        echo -e "${Bl} Current emoji: $(cat $MODDIR/cemoji)${N}"
        echo -e "$div"
        echo -e "${Bl} Available options:${N}"
        echo -e "${Bl}  1. Change your font${N}"
        echo -e "${Bl}  2. Change your emoji${N}"
        echo -e "${Bl}  3. Apply custom font or emoji${N}"
        echo -e "${Bl}  4. Revert to stock font and emoji${N}"
        echo -e "${Bl}  5. Reboot to apply changes${N}"
        echo -e "${Bl}  6. Preview fonts and request new ones${N}"
        echo -e "${Bl}  7. Donate to Androidacy${N}"
        echo -e "${Bl}  8. Help and feedback${N}"
        echo -e "${Bl}  9. Quit${N}"
        echo -e "$div"
        echo -en "${Bl} Your selection: "
        read -r a
        case $a in
        1*) font_select ;;
        2*) emoji_select ;;
        3*) custom_font ;;
        4*) rever_st ;;
        5*) reboot_fn ;;
        6*) open_link "font-previewer" ;;
        7*) open_link "donate" ;;
        8*) open_link "contact" ;;
        9*) do_quit ;;
        *) echo -e "${R} Invalid option, please try again${N}" && sleep 2 && menu_set ;;
        esac
    done
}
# Checks for lists updates. Maybe in the future for module updates.
# updateCheck() {
#     do_banner
#     log 'INFO' 'Starting update check'
#     echo -e "${Bl} Checking for list updates...${N}"
#     updateChecker 'lists'
#     listtVersion=$response
#     if test "$(cat "$MODDIR"/lists/lists.version)" -lt "$listVersion"; then
#         echo -e "${Bl} Lists update found! Updating to v${listVersion}${N}"
#         downloadFile 'lists' 'fonts-list' 'txt' "$MODPATH/lists/fonts.list"
#         downloadFile 'lists' 'emojis-list' 'txt' "$MODPATH/lists/emojis.list"
#         sed -i 's/[.]zip$//g' "$MODPATH"/lists/*
#         cp -f "$MODPATH"/lists/* "$EXT_DATA"/lists
#         updateChecker 'lists'
#         echo "$response" >"$MODPATH"/lists/lists.version
#         echo -e "${Bl} Lists updated! Proceeding to menu!${N}"
#     else
#         echo -e "${Bl} No lists update found! Proceeding to menu${N}"
#     fi
#     echo -e "${Bl} Checking for module updates...${N}"
#     updateChecker 'self'
#     newVersion=$response
#     if test "$(grep 'versionCode=' "$MODDIR"/module.prop | sed 's/versionCode=//')" -lt "$newVersion"; then
#         echo -e "${Bl} Module update found! Please download the latest update manually, and flash in magisk manager or FoxMMM.${N}"
#         echo -e "${Bl} Attempting to launch downloads page...${N}"
#         sleep 2
#         am start -a android.intent.action.VIEW -d "https://www.androidacy.com/modules-repo/?utm_source=fontmanager&utm_medium=repo&utm_campaign=update_module#fontrevival" &>/dev/null
#         echo -e "${Bl} Exiting now.!${N}"
#         exit 1
#     else
#         echo -e "${Bl} No module update found! Proceeding to menu${N}"
#     fi
# }
# updateCheck
detect_others
menu_set
