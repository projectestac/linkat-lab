#!/bin/bash
N_PARAMS=$#
if [ $N_PARAMS == 0 ]; then
        if [ -f /opt/configuracio/caf_remote_install_flag ]; then
                sudo sudo -u suport DISPLAY=:0.0 zenity --error --width=400 --height=200 --title "Configuració CA" --text "L'agent de CA s'està instal·lant de forma automàtica. Es finalitza la instal·lació manual."
                exit 0
        fi
#	dpkg --configure -a
	sleep 3 | tee >(sudo sudo -u suport DISPLAY=:0.0 zenity --progress --pulsate --no-cancel --auto-close --text="Actualitzant l'equip..." 2>/dev/null)
#	apt update
#	apt -f -y install
	sleep 3 | tee >(sudo sudo -u suport DISPLAY=:0.0 zenity --progress --pulsate --no-cancel --auto-close --text="Instal·lant els paquets necessaris..." 2>/dev/null)
#	apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
#	snap refresh
	. /opt/configuracio/config-nom.sh
	. /opt/configuracio/config-ca.sh
else
#
# El paràmetre que s'envia als scripts no és important ja que s'utilitza per detectar que
# el nombre de paràmetres és diferent de zero.
#
	. /opt/configuracio/config-nom.sh CLI
	. /opt/configuracio/config-ca.sh CLI
fi
