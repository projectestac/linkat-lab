#!/bin/bash
#
# Personalització de l'entorn d'escriptori de l'alumne/a
#
GSETTINGS="$(which gsettings)"
KEY=""
source "$HOME"/.config/user-dirs.dirs

# Definició del fons d'escriptori i tema de l'entorn GNOME
#
$GSETTINGS set org.gnome.desktop.screensaver picture-uri 'file:///usr/share/linkat/linkat-usuari-corporatiu-custom/background1920x1080-dark.jpg'
$GSETTINGS set org.gnome.desktop.background picture-uri 'file:///usr/share/linkat/linkat-usuari-corporatiu-custom/background1920x1080-dark.jpg'
$GSETTINGS set org.gnome.desktop.screensaver picture-options 'zoom'
$GSETTINGS set org.gnome.desktop.background picture-options 'zoom'
$GSETTINGS set com.canonical.unity-greeter background 'file:///usr/share/linkat/linkat-usuari-corporatiu-custom/background1920x1080-dark.jpg'
$GSETTINGS set org.gnome.desktop.wm.preferences theme 'Radiance'
$GSETTINGS set org.gnome.desktop.interface gtk-theme 'Radiance'
$GSETTINGS set com.canonical.indicator.session user-show-menu false
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
# Es programen les tecles <Control><Alt>l per bloquejar la pantalla
#
KEY=$(gsettings get org.gnome.settings-daemon.plugins.media-keys screensaver)
if [ "$KEY" != "'<Control><Alt>l'" ]; then
	$GSETTINGS set org.gnome.settings-daemon.plugins.media-keys screensaver "'<Control><Alt>l'"
fi

#
# Es deshabilita l'intercanvi ràpid d'usuari
#
KEY=$(gsettings get org.gnome.desktop.lockdown disable-user-switching)
if [ "$KEY" != "true" ]; then
	$GSETTINGS set org.gnome.desktop.lockdown disable-user-switching true
fi

#
# Es desachabilita la icona "Servidors de xarxa"
#
KEY=$(gsettings get org.gnome.nautilus.desktop network-icon-visible)
if [ "$KEY" != "false" ]; then
	$GSETTINGS set org.gnome.nautilus.desktop network-icon-visible false
fi

#
# Es desactiva l'assistent d'inici a l'entrada d'usuari
#

if [ ! -e "$HOME"/.config/gnome-initial-setup-done ]; then
	touch "$HOME"/.config/gnome-initial-setup-done
fi
#
# Es configura el navegador Chromium perquè funcioni amb el DNI-e
#
if [ ! -d "$HOME"/.pki ]; then
	mkdir -p "$HOME"/.pki/nssdb
	modutil -dbdir sql:"$HOME"/.pki/nssdb/ -add "DNI-e" -libfile /usr/lib/libpkcs11-fnmtdnie.so
fi
if [ -e /opt/cisco/anyconnect/bin/vpnui ]; then
	LOCAL_IP="$(hostname -I)"
	while [ "$LOCAL_IP" == "" ]; do
		sleep 5
		LOCAL_IP="$(hostname -I)"
	done
	if [[ $LOCAL_IP != 10* ]]; then
		nohup /opt/cisco/anyconnect/bin/vpnui > /dev/null 2>&1 &
	fi
fi 
exit 0
