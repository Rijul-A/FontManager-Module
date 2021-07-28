#!/bin/bash

# Title: Androidacy API shell client
# Description: Provides an interface to the Androidacy API
# License: AOSL
# Version: 1.0.3

# Initiliaze the API
initClient() {
    if test "$#" -ne 2; then
        echo "Illegal number of parameters passed. Expected two, got $#"
        abort
    else
        export API_URL='https://test-api.androidacy.com'
        if test "$1" = 'fm'; then
            export API_FN="FontManager"
        elif test "$1" = 'wvm'; then
            export API_FN="WebviewManager"
        fi
        export API_V=$2
        export API_APP=$1
        buildClient
        initTokens
        if ! wget -U "$API_UA" --header="Accept-Language: $API_LANG" --post-data "app=$app&token=$API_TOKEN" $API_URL/ping; then
          echo "API unreachable! Try again in a few minutes"
          abort
        fi
        export __API_INIT_DONE=true
    fi
}

# Build client requests
buildClient() {
    android=$(resetprop ro.system.build.version.release || resetprop ro.build.version.release)
    device=$(resetprop ro.product.model | sed 's#\n#%20#g' || resetprop ro.product.device | sed 's#\n#%20#g' || resetprop ro.product.vendor.device | sed 's#\n#%20#g' || resetprop ro.product.system.model | sed 's#\n#%20#g' || resetprop ro.product.vendor.model | sed 's#\n#%20#g' || resetprop ro.product.name | sed 's#\n#%20#g')
    lang=$(resetprop persist.sys.locale | sed 's#\n#%20#g' || resetprop ro.product.locale | sed 's#\n#%20#g')
    export API_UA="Mozilla/5.0 (Linux; Android $android; $device) AppleWebKit/537.36 (KHTML, like Gecko) 
Chrome/68.0.3440.91 Mobile Safari/537.36 [${API_FN}/${API_V}]"
    export API_LANG=$lang
}

# Tokens init
initTokens() {
    if test -f /sdcard/.androidacy; then
        API_TOKEN=$(cat /sdcard/.androidacy)
    else
        wget -U "$API_UA" --header="Accept-Language: $API_LANG" --post-data 'app=tokens' "$API_URL/tokens/get" -O /sdcard/.androidacy
        API_TOKEN=$(cat /sdcard/.androidacy)
    fi
    export API_TOKEN
    validateTokens "$API_TOKEN"
}

# Check that we have a valid token
validateTokens() {
    if test "$#" -ne 1; then
        echo "Illegal number of parameters passed. Expected one, got $#"
        abort
    else
        API_LVL=$(wget -U "$API_UA" --header="Accept-Language: $API_LANG" --post-data "app=tokens&token=$API_TOKEN" "$API_URL/tokens/validate" -O -)
        if test $? -ne 0; then
            # Restart process on validation failure
            rm -f '/sdcard/.androidacy'
            initTokens
        else
            # Pass the appropriate API access level back to the caller
            export API_LVL
        fi
    fi
    if test "$API_LVL" -lt 2; then
        echo '- Looks like your using a free or guest token'
        echo '- For info on faster downloads, see https://www.androidacy.com/'
    fi
}

# Handle and decode file list JSON
getList() {
    if test "$#" -ne 1; then
        echo "Illegal number of parameters passed. Expected one, got $#"
        abort
    else
        if ! $__API_INIT_DONE; then
            echo "Tried to call getList without first initializing the API client!"
            abort
        fi
        local app=$API_APP
        local cat=$1
        if test "$app" = 'beta' && test API_LVL -lt 4; then
            echo "Error! Access denied for beta."
            abort
        fi
        response=$(wget -U "$API_UA" --header="Accept-Language: $API_LANG" --post-data "app=$app&category=$cat&token=$API_TOKEN" $API_URL/downloads/list  -O -)
        if test $? -ne 0; then
            echo "API request failed! Assuming API is down and aborting!"
            abort
        fi
        # shellcheck disable=SC2001
        parsedList=$(echo "$response" | sed 's/[^a-zA-Z0-9]/ /g')
        response="$parsedList"
    fi
}

# Handle file downloads
downloadFile() {
    if test "$#" -ne 4; then
        echo "Illegal number of parameters passed. Expected four, got $#"
        abort
        if ! $__API_INIT_DONE; then
            echo "Tried to call downloadFile without first initializing the API client!"
            abort
        fi
    else
        local cat=$1
        local file=$2
        local format=$3
        local location=$4
        local app=$API_APP
        if test "$API_LVL" -lt 2; then
            local endpoint='downloads/free'
        else
            local endpoint='downloads/paid'
        fi
        wget -U "$API_UA" --header="Accept-Language: $API_LANG" --post-data "app=$app&category=$cat&request=$file&format=$format&token=$API_TOKEN" "$API_URL/$endpoint" -O "$location"
        if test $? -ne 0; then
            echo "API request failed! Assuming API is down and aborting!"
            abort
        fi
    fi
}

# Handle uptdates checking
updateChecker() {
    if test "$#" -ne 1; then
        echo "Illegal number of parameters passed. Expected one, got $#"
        abort
        if ! $__API_INIT_DONE; then
            echo "Tried to call updateChecker without first initializing the API client!"
            abort
        fi
    else
        local cat=$1
        local app=$API_APP
        response=$(wget -U "$API_UA" --header="Accept-Language: $API_LANG" --post-data "app=$app&category=$cat&token=$API_TOKEN" "$API_URL/downloads/updates"  -O -)
        # shellcheck disable=SC2001
        parsedList=$(echo "$response" | sed 's/[^a-zA-Z0-9]/ /g')
        response="$parsedList"
    fi
}

# Handle checksums
getChecksum() {
     if test "$#" -ne 3; then
        echo "Illegal number of parameters passed. Expected three, got $#"
        abort
        if ! $__API_INIT_DONE; then
            echo "Tried to call getChecksum without first initializing the API client!"
            abort
        fi
    else
        local cat=$1
        local file=$2
        local format=$3
        local app=$API_APP
        response=$(wget -U "$API_UA" --header="Accept-Language: $API_LANG" --post-data "app=$app&category=$cat&request=$file&format=$format&token=$API_TOKEN" $API_URL'/checksum/get'  -O -)
        if test $? -ne 0; then
            echo "API request failed! Assuming API is down and aborting!"
            abort
        fi
    fi
}