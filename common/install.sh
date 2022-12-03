# shellcheck shell=bash
# shellcheck disable=SC2169,SC2121,SC2154
set -x
ui_print "ⓘ Welcome to Font Manager!"
# updateChecker 'self'
# newVersion=$response
# log 'INFO' "Running update check with module $MODULE_VERSIONCODE and server version $newVersion"
# if test "$MODULE_VERSIONCODE" -lt "$newVersion"; then
# 	echo -e "${Bl} Module update found! Please download the latest update manually, and install in magisk manager.${N}"
# 	echo -e "${Bl} Attempting to launch downloads page...${N}"
# 	sleep 2
# 	am start -a android.intent.action.VIEW -d "https://www.androidacy.com/modules-repo/#fontrevival?utm_source=fontmanager&utm_medium=repo&utm_campaign=update_module#fontrevival" &>/dev/null
# 	echo -e "${Bl} Exiting now.!${N}"
# 	exit 1
# fi
xml_s() {
	# TDOD: refactor this as no one remembers how it works
	ui_print "ⓘ Registering our fonts, and reverting to default font."
	for i in $(cmd overlay list|grep font|sed 's/....//'); do cmd overlay disable "$i"; done
	SXML="$MODPATH"/system/etc/fonts.xml
	mkdir -p "$MODPATH"/system/etc
	cp -rf /system/etc/fonts.xml "$MODPATH"/system/etc
	DF=$(sed -n '/"sans-serif">/,/family>/p' "$SXML" | grep '\-Regular.' | sed 's/.*">//;s/-.*//' | tail -1)
	set BlackItalic Black BoldItalic Bold MediumItalic Medium Italic Regular LightItalic Light ThinItalic Thin
	for i; do
		sed -i "/\"sans-serif\">/,/family>/s/$DF-$i/Roboto-$i/" "$SXML"
	done
	set BlackItalic Black BoldItalic Bold MediumItalic Medium Italic Regular LightItalic Light ThinItalic Thin
	for i; do
		sed -i "s/NotoSerif-$i/Roboto-$i/" "$SXML"
	done
	if grep -q OnePlus "$SXML"; then
		if test -f /system/etc/fonts_base.xml; then
			cp /system/etc/fonts_base.xml "$MODPATH"/system/etc/fonts_base.xml
			sed -i "/\"sans-serif\">/,/family>/s/$DF/Roboto/" "$MODPATH"/system/etc/fonts_base.xml
		fi
	fi
	if grep -q miui "$SXML"; then
		set Black Bold Medium Regular Light Thin
		if test "$i" = "Black"; then
			sed -i '/"mipro-bold"/,/family>/{/700/s/MiLanProVF/Black/;/stylevalue="700"/d}' "$SXML"
			sed -i '/"mipro-heavy"/,/family>/{/400/s/MiLanProVF/Black/;/stylevalue="700"/d}' "$SXML"
		elif test "$i" = "Bold"; then
			sed -i '/"mipro"/,/family>/{/700/s/MiLanProVF/Bold/;/stylevalue="400"/d}' "$SXML"
			sed -i '/"mipro-medium"/,/family>/{/700/s/MiLanProVF/Bold/;/stylevalue="480"/d}' "$SXML"
			sed -i '/"mipro-demibold"/,/family>/{/700/s/MiLanProVF/Bold/;/stylevalue="540"/d}' "$SXML"
			sed -i '/"mipro-semibold"/,/family>/{/700/s/MiLanProVF/Bold/;/stylevalue="630"/d}' "$SXML"
			sed -i '/"mipro-bold"/,/family>/{/400/s/MiLanProVF/Bold/;/stylevalue="630"/d}' "$SXML"
		elif test "$i" = "Medium"; then
			sed -i '/"mipro-regular"/,/family>/{/700/s/MiLanProVF/Medium/;/stylevalue="400"/d}' "$SXML"
			sed -i '/"mipro-medium"/,/family>/{/400/s/MiLanProVF/Medium/;/stylevalue="400"/d}' "$SXML"
			sed -i '/"mipro-demibold"/,/family>/{/400/s/MiLanProVF/Medium/;/stylevalue="480"/d}' "$SXML"
			sed -i '/"mipro-semibold"/,/family>/{/400/s/MiLanProVF/Medium/;/stylevalue="540"/d}' "$SXML"
		elif test "$i" = "Regular"; then
			sed -i '/"mipro"/,/family>/{/400/s/MiLanProVF/Regular/;/stylevalue="340"/d}' "$SXML"
			sed -i '/"mipro-light"/,/family>/{/700/s/MiLanProVF/Regular/;/stylevalue="305"/d}' "$SXML"
			sed -i '/"mipro-normal"/,/family>/{/700/s/MiLanProVF/Regular/;/stylevalue="340"/d}' "$SXML"
			sed -i '/"mipro-regular"/,/family>/{/400/s/MiLanProVF/Regular/;/stylevalue="340"/d}' "$SXML"
		elif test "$i" = "Light"; then
			sed -i '/"mipro-thin"/,/family>/{/700/s/MiLanProVF/Light/;/stylevalue="200"/d}' "$SXML"
			sed -i '/"mipro-extralight"/,/family>/{/700/s/MiLanProVF/Light/;/stylevalue="250"/d}' "$SXML"
			sed -i '/"mipro-light"/,/family>/{/400/s/MiLanProVF/Light/;/stylevalue="250"/d}' "$SXML"
			sed -i '/"mipro-normal"/,/family>/{/400/s/MiLanProVF/Light/;/stylevalue="305"/d}' "$SXML"
		elif test "$i" = "Thin"; then
			sed -i '/"mipro-thin"/,/family>/{/400/s/MiLanProVF/Thin/;/stylevalue="150"/d}' "$SXML"
			sed -i '/"mipro-extralight"/,/family>/{/400/s/MiLanProVF/Thin/;/stylevalue="200"/d}' "$SXML"
		fi
	fi
	if grep -q lg-sans-serif "$SXML"; then
		sed -i '/"lg-sans-serif">/,/family>/{/"lg-sans-serif">/!d};/"sans-serif">/,/family>/{/"sans-serif">/!H};/"lg-sans-serif">/G' "$SXML"
	fi
	if [ -f "$OD"/system/etc/fonts_lge.xml ]; then
		cp -rf "$OD"/system/etc/fonts_lge.xml "$MODPATH"/system/etc
		local LXML=$SYSETC/fonts_lge.xml
		set BlackItalic Black BoldItalic Bold MediumItalic Medium Italic Regular LightItalic Light ThinItalic Thin
		for i; do
			sed -i "/\"default_roboto\">/,/family>/s/Roboto-$i/$i/" "$LXML"
		done
	fi
	if grep -q Samsung "$SXML"; then
		sed -i 's/SECRobotoLight-/Roboto-/' "$SXML"
		sed -i 's/SECCondensed-/RobotoCondensed-/' "$SXML"
	fi
	if grep -q COLOROS "$SXML"; then
		if [ -f "$OD"/system/etc/fonts_base.xml ]; then
			local RXML=$SYSETC/fonts_base.xml
			cp "$SXML" "$RXML"
			sed -i "/\"sans-serif\">/,/family>/s/$DF/Roboto/" "$RXML"
		fi
	fi
        # Android 13, might help on 12
        sed -i 's/style=\"italic\">Roboto-Regular\.ttf/style="italic">Roboto-Italic.ttf/gi' "$RXML"
        sed -i 's/weight=\"900\"\ style=\"normal\">Roboto-Regular.ttf/weight="900" style="normal">Roboto-Bold.ttf/gi' "$RXML"
        sed -i 's/weight=\"900\"\ style=\"italic\">Roboto-Italic.ttf/weight="900" style="italic">Roboto-BoldItalic.ttf/gi' "$RXML"
        sed -i 's/weight=\"800\"\ style=\"normal\">Roboto-Regular.ttf/weight="900" style="normal">Roboto-Bold.ttf/gi' "$RXML"
        sed -i 's/weight=\"800\"\ style=\"italic\">Roboto-Italic.ttf/weight="900" style="italic">Roboto-BoldItalic.ttf/gi' "$RXML"
        sed -i 's/weight=\"700\"\ style=\"normal\">Roboto-Regular.ttf/weight="900" style="normal">Roboto-Bold.ttf/gi' "$RXML"
        sed -i 's/weight=\"700\"\ style=\"italic\">Roboto-Italic.ttf/weight="900" style="italic">Roboto-BoldItalic.ttf/gi' "$RXML"
}
get_lists() {
	ui_print "ⓘ Excellent, you have internet."
	ui_print "ⓘ Downloading extra files..."
	mkdir -p "$MODPATH"/lists
	mkdir -p "$EXT_DATA"/lists
	mkdir -p "$EXT_DATA"/font
	mkdir -p "$EXT_DATA"/emoji
	# downloadFile 'lists' 'fonts-list' 'txt' "$MODPATH/lists/fonts.list"
	# downloadFile 'lists' 'emojis-list' 'txt' "$MODPATH/lists/emojis.list"
	sed -i 's/[.]zip$//g' "$MODPATH"/lists/*
	# updateChecker 'lists'
	# echo "$response" >"$MODPATH"/lists/lists.version
	for i in etc fonts; do
		if [ ! -d "$MODPATH"/system/$i ]; then
			mkdir -p "$MODPATH"/system/$i
		fi
	done
	cp -f "$MODPATH"/lists/* "$EXT_DATA"/lists
	xml_s
}
setup_script() {
	chmod 755 -R "$MODPATH"/system/bin/
	rm -fr /data/fonts/*
	chattr +i /data/fonts
        chmod -R 444 /data/fonts
}
extra_cleanup() {
	mv "$MODPATH"/common/tools/fontmanager.sh "$MODPATH"/tools/fontmanager
	mv "$MODPATH"/common/apiClient.sh "$MODPATH"/tools/apiClient
	mv "$MODPATH"/common/tools/utils.sh "$MODPATH"/tools/utils
	mv "$MODPATH/common/tools/bash-$ARCH" "$MODPATH/tools/bash"
	# mv "$MODPATH/common/tools/curl-$ARCH" "$MODPATH/tools/curl"
	rm -fr "$MODPATH"/common/
	rm -rf "$MODPATH"/*.md
	rm -rf "$MODPATH"/LICENSE
}
preserve_fonts() {
	if [ -f /data/adb/modules/fontrevival/system/fonts/*.ttf ]; then
		ui_print "⚠ Preserving existing font/emoji selection"
		mkdir $MODPATH/system/fonts/
		cp -fr /data/adb/modules/fontrevival/system/fonts/*.ttf $MODPATH/system/fonts/
		cp /data/adb/modules/fontrevival/cfont $MODPATH/cfont
		cp /data/adb/modules/fontrevival/cfont $MODPATH/cemoji
	fi
	if [ -f /data/adb/modules/fontrevival/system/product/fonts/*.ttf ]; then
		mkdir $MODPATH/system/product/fonts/
		cp -fr /data/adb/modules/fontrevival/system/product/fonts/*.ttf $MODPATH/product/fonts/
		cp /data/adb/modules/fontrevival/cfont $MODPATH/cfont
		cp /data/adb/modules/fontrevival/cfont $MODPATH/cemoji
	fi
}
get_lists
setup_script
extra_cleanup
preserve_fonts
{
	echo "Here's some useful links:"
	echo " "
	echo "Website: https://www.androidacy.com"
	echo "Donate: https://www.androidacy.com/donate/"
	echo "Support and contact: https://www.anroidacy.com/contact/"
 echo "Run exactly 'su -c manage_fonts' in TermUX (recommended)"
} >"$EXT_DATA"/README.txt
ui_print "⚠ Please make sure not to have any other font changing modules installed ⚠"
ui_print "⚠ Please remove any such module, as it conflicts with this one ⚠"
ui_print "ⓘ Once you reboot, run exactly 'su -c manage_fonts' in TermUX (recommended)"
sleep 1
# am start -a android.intent.action.VIEW -d "https://www.androidacy.com/install-done/?f=fontmanager&r=fmi&v=$MODULE_VERSION" &>/dev/null
