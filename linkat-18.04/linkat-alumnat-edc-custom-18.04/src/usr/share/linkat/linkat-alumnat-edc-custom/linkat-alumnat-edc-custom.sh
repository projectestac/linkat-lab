#!/bin/bash
#
# Personalització de l'entorn d'escriptori de l'alumne/a
#
GSETTINGS="$(which gsettings)"
FIREFOX="$(which firefox)"
ZENITY="$(which zenity)"
KEY=""
source "$HOME"/.config/user-dirs.dirs
#
# Directori on es troba l'escriptori de l'usuari: $XDG_DESKTOP_DIR
#
if [ -e "$XDG_DESKTOP_DIR/Canvi-contrasenya-AZ.desktop" ]; then
	if [ -n "$(grep -i "portal.microsoftonline.com" "$XDG_DESKTOP_DIR/Canvi-contrasenya-AZ.desktop")" ]; then
		sed -i 's/portal.microsoftonline.com\/ChangePassword.aspx/myaccount.microsoft.com/g' "$XDG_DESKTOP_DIR/Canvi-contrasenya-AZ.desktop"
	fi
fi
unzip -n -q -d "$XDG_DESKTOP_DIR" /usr/share/linkat/linkat-alumnat-edc-custom/edu-links.zip
#
# Definició del fons d'escriptori i tema de l'entorn GNOME
#
$GSETTINGS set org.gnome.desktop.screensaver picture-uri 'file:///usr/share/linkat/linkat-alumnat-edc-custom/FONS-ESCRIPTORI-ALUMNAT.jpg'
$GSETTINGS set org.gnome.desktop.background picture-uri 'file:///usr/share/linkat/linkat-alumnat-edc-custom/FONS-ESCRIPTORI-ALUMNAT.jpg'
$GSETTINGS set org.gnome.desktop.screensaver picture-options 'zoom'
$GSETTINGS set org.gnome.desktop.background picture-options 'zoom'
$GSETTINGS set com.canonical.unity-greeter background 'file:///usr/share/linkat/linkat-alumnat-edc-custom/FONS-ESCRIPTORI-ALUMNAT.jpg'
$GSETTINGS set org.gnome.desktop.wm.preferences theme 'Radiance'
$GSETTINGS set org.gnome.desktop.interface gtk-theme 'Radiance'
$GSETTINGS set com.canonical.indicator.session user-show-menu false
$GSETTINGS set org.gnome.settings-daemon.plugins.housekeeping ignore-paths "['/opt/configuracio/mnt-recuperacio']"
#
# Temps per posar la pantalla en negre: idle-delay-> 12 minuts (720 seg)
#
KEY=$(gsettings get org.gnome.desktop.session idle-delay | cut -d " " -f2)
if [ "$KEY" != "720" ]; then
	$GSETTINGS set org.gnome.desktop.session idle-delay 720
fi
#
# Corrent Altern (AC): Suspensio de la maquina al cap d'1 hora. -> sleep-inactive-ac-timeout: 1 hora (3600 s)
#
KEY=$(gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout)
if [ "$KEY" != "3600" ]; then
	$GSETTINGS set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 3600
	$GSETTINGS set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type suspend
fi

#
# Bateria: Suspensio de la maquina al cap de 20 minuts -> sleep-inactive-ac-timeout: 20 min (1200 s)
#
KEY=$(gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout)
if [ "$KEY" != "1200" ]; then
	$GSETTINGS set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 1200
	$GSETTINGS set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type suspend
fi
#
# Temps de bloqueig de la pantalla. 3 minuts després de saltar el "idle-delay" (15 minuts des de l'inici de la inactivitat)
#
KEY=$(gsettings get org.gnome.desktop.screensaver lock-delay | cut -d " " -f2)
if [ "$KEY" != "180" ]; then
	$GSETTINGS set org.gnome.desktop.screensaver lock-delay 180
	$GSETTINGS set org.gnome.desktop.screensaver lock-enabled true
fi

#
# Brillantor de pantalla
#
KEY=$(gsettings get com.ubuntu.touch.system brightness)
if [ "$KEY" != "60" ]; then
	$GSETTINGS set com.ubuntu.touch.system brightness 60
	$GSETTINGS set com.ubuntu.touch.system brightness-needs-hardware-default false
	$GSETTINGS set com.ubuntu.touch.system auto-brightness true
fi
#
# Habilitar tecles TouchPad
#
KEY=$(gsettings get org.gnome.desktop.peripherals.touchpad click-method)
if [ "$KEY" != "'areas'" ]; then
	$GSETTINGS set org.gnome.desktop.peripherals.touchpad  click-method areas 
fi
#
# Desactivació dels serveis de GEOIP
#
KEY=$(gsettings get org.gnome.system.location enabled)
if [ "$KEY" != "false" ]; then
	$GSETTINGS set org.gnome.system.location enabled  false
fi
#
# Es programa la tecla Win per desplegar el menú d'aplicacions
#
KEY=$(gsettings get org.gnome.desktop.wm.keybindings panel-main-menu)
if [ "$KEY" != "['Super_L']" ]; then
	$GSETTINGS set org.gnome.desktop.wm.keybindings panel-main-menu "['Super_L']"
fi
#
#
# Es programen les tecles <Control><Alt>l per bloquejar la pantalla
#
KEY=$(gsettings get org.gnome.settings-daemon.plugins.media-keys screensaver)
if [ "$KEY" != "'<Control><Alt>l'" ]; then
	$GSETTINGS set org.gnome.settings-daemon.plugins.media-keys screensaver "'<Control><Alt>l'"
fi
#
# Es copia el fitxer gtk-3.0 per canviar el color del text de les icones de l'escriptori
#
cp /usr/share/linkat/linkat-alumnat-edc-custom/gtk.css "$HOME"/.config/gtk-3.0
#
# Es desactiva l'assistent d'inici a l'entrada d'usuari
#
if [ ! -e "$HOME"/.config/gnome-initial-setup-done ]; then
	touch "$HOME"/.config/gnome-initial-setup-done
fi
#
# Canvi de pàgina d'inici Firefox
#
if [ ! -d "$HOME"/.mozilla ]; then
	LANG=ca_ES.UTF-8 "$FIREFOX"  --headless --new-instance --first-startup >/dev/null 2>&1  &
	while [ ! -d "$HOME"/.mozilla ]
	do
	   sleep 1
	done
	killall -s TERM firefox >/dev/null 2>&1
fi
PERFIL=$(grep Default "$HOME"/.mozilla/firefox/installs.ini |cut -d '=' -f2)
echo "user_pref(\"browser.startup.homepage\", \"http://edu365.cat\");" > "$HOME"/.mozilla/firefox/"$PERFIL"/user.js

#
# Mostra un missatge per pantalla recordant que la contrasenya està a punt de caducar
#
START_PASSWORD="$(date -d "$(passwd -S| cut -d " " -f 3)" "+%s")"
END_PASSWORD="$(passwd -S| cut -d " " -f 5)"
if [ "$END_PASSWORD" -eq "99999" ]; then
   exit 0
fi
let 'END_PASSWORD *= 86400'
DELTA_TIME="$(passwd -S| cut -d " " -f 6)"
let 'DELTA_TIME *= 86400'
let 'WARNING_PASSWORD = START_PASSWORD+END_PASSWORD-DELTA_TIME'
REAL_DATE="$(date -d "$(date +%m/%d/%Y)"  "+%s")"
if [ "$REAL_DATE" -ge "$WARNING_PASSWORD" ]; then
	SHOW_DAYS=""
	let 'SHOW_DAYS = START_PASSWORD+END_PASSWORD-REAL_DATE'
	let 'SHOW_DAYS /= 86400'
	$ZENITY --warning --width=400 --text="La contrasenya caducarà en menys de $SHOW_DAYS dies.\n\r
Heu d'anar a:\n\r
<b>Paràmetres del Sistema-> Detalls-> Usuaris</b>\n\r
i clicar a sobre de l'opció <b>Contrasenya</b> per canviar-la."
fi
exit 0
