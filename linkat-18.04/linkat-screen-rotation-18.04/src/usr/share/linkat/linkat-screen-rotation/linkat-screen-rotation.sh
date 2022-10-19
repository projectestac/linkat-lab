#!/bin/bash
ZENITY=$(which zenity)
GSETTINGS=$(which gsettings)
KEY=$(gsettings get org.gnome.settings-daemon.peripherals.touchscreen orientation-lock)
if [ "$KEY" != "true" ]; then
	gsettings set org.gnome.settings-daemon.peripherals.touchscreen orientation-lock true
	gsettings set org.gnome.settings-daemon.plugins.orientation active false
	$ZENITY --info --width=300 --text "Rotació de pantalla <b>BLOCADA</b>."
else
	gsettings set org.gnome.settings-daemon.peripherals.touchscreen orientation-lock false
	gsettings set org.gnome.settings-daemon.plugins.orientation active true
	$ZENITY --info --width=300 --text "Rotació de pantalla <b>DESBLOCADA</b>."
fi
exit 0
